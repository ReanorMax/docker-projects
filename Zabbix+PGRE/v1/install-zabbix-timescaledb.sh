#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: что-то пошло не так. Проверьте логи.${NC}"
        exit 1
    fi
}

# Функция для проверки готовности PostgreSQL
wait_for_postgres() {
    local container_id=$1
    local max_retries=30
    local retry_count=0

    echo -e "${GREEN}Ожидание готовности PostgreSQL...${NC}"
    while ! docker exec "$container_id" pg_isready -U zabbix > /dev/null 2>&1; do
        sleep 5
        retry_count=$((retry_count + 1))
        if [ $retry_count -ge $max_retries ]; then
            echo -e "${RED}Ошибка: PostgreSQL не запустился за отведённое время.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Попытка подключения к PostgreSQL ($retry_count/$max_retries)...${NC}"
    done
    echo -e "${GREEN}PostgreSQL готов к работе.${NC}"
}

# Шаг 1: Проверка наличия архива
ARCHIVE_PATH="/root/offline-install.tar.gz"
INSTALL_DIR="/root/offline-install"

if [ ! -f "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Ошибка: файл $ARCHIVE_PATH не найден. Поместите архив offline-install.tar.gz в /root.${NC}"
    exit 1
fi
echo -e "${GREEN}Архив найден: $ARCHIVE_PATH${NC}"

# Шаг 2: Распаковка архива
echo -e "${GREEN}Распаковка архива в $INSTALL_DIR...${NC}"
mkdir -p "$INSTALL_DIR"
tar -xvzf "$ARCHIVE_PATH" -C /root
check_error
cd "$INSTALL_DIR" || { echo -e "${RED}Не удалось перейти в директорию ${INSTALL_DIR}${NC}"; exit 1; }

# Шаг 3: Установка Docker
echo -e "${GREEN}Установка Docker...${NC}"
DOCKER_PACKAGES_DIR="$INSTALL_DIR/packages/docker-packages"
if [ ! -d "$DOCKER_PACKAGES_DIR" ] || [ -z "$(ls -A $DOCKER_PACKAGES_DIR)" ]; then
    echo -e "${RED}Ошибка: директория $DOCKER_PACKAGES_DIR пуста или не существует. Проверьте содержимое архива.${NC}"
    exit 1
fi
dpkg -i "$DOCKER_PACKAGES_DIR"/*.deb
apt-get install -f -y
check_error

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Ошибка: Docker не установлен. Проверьте логи.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker успешно установлен.${NC}"

# Шаг 4: Установка Docker Compose
echo -e "${GREEN}Установка Docker Compose...${NC}"
cp "$INSTALL_DIR/docker-compose" /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
check_error
echo -e "${GREEN}Docker Compose успешно установлен.${NC}"

# Шаг 5: Загрузка Docker-образов
echo -e "${GREEN}Загрузка Docker-образов...${NC}"
DOCKER_IMAGES_DIR="$INSTALL_DIR/docker-images"
if [ ! -d "$DOCKER_IMAGES_DIR" ] || [ -z "$(ls -A $DOCKER_IMAGES_DIR)" ]; then
    echo -e "${RED}Ошибка: директория $DOCKER_IMAGES_DIR пуста или не существует. Проверьте содержимое архива.${NC}"
    exit 1
fi
docker load -i "$DOCKER_IMAGES_DIR/postgres-timescaledb-17.tar"
docker load -i "$DOCKER_IMAGES_DIR/zabbix-server-pgsql.tar"
docker load -i "$DOCKER_IMAGES_DIR/zabbix-web-nginx-pgsql.tar"
check_error
echo -e "${GREEN}Docker-образы успешно загружены.${NC}"

# Шаг 6: Обновление docker-compose.yml
echo -e "${GREEN}Обновление файла docker-compose.yml для настройки TimescaleDB...${NC}"
if grep -q "environment:" "$INSTALL_DIR/docker-compose.yml"; then
    sed -i '/environment:/a       POSTGRES_INITDB_ARGS: --data-checksums' "$INSTALL_DIR/docker-compose.yml"
    sed -i '/POSTGRES_INITDB_ARGS/a       POSTGRES_HOST_AUTH_METHOD: trust' "$INSTALL_DIR/docker-compose.yml"
    sed -i '/POSTGRES_HOST_AUTH_METHOD/a       TIMESCALEDB_TELEMETRY: "off"' "$INSTALL_DIR/docker-compose.yml"
    sed -i '/TIMESCALEDB_TELEMETRY/a       POSTGRES_CONFIG_SHARED_PRELOAD_LIBRARIES: "timescaledb"' "$INSTALL_DIR/docker-compose.yml"
else
    sed -i 's/image: postgres-timescaledb:17/image: postgres-timescaledb:17
    environment:
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: your_zabbix_password
      POSTGRES_INITDB_ARGS: --data-checksums
      POSTGRES_HOST_AUTH_METHOD: trust
      TIMESCALEDB_TELEMETRY: "off"
      POSTGRES_CONFIG_SHARED_PRELOAD_LIBRARIES: "timescaledb"/' "$INSTALL_DIR/docker-compose.yml"
fi
check_error
echo -e "${GREEN}Файл docker-compose.yml успешно обновлён.${NC}"

# Шаг 7: Запуск контейнеров
echo -e "${GREEN}Запуск контейнеров через docker-compose...${NC}"
cd "$INSTALL_DIR" || exit 1
docker-compose down
docker-compose up -d
check_error
echo -e "${GREEN}Контейнеры успешно запущены.${NC}"

# Шаг 8: Добавление параметра в postgresql.conf
echo -e "${GREEN}Добавление TimescaleDB в shared_preload_libraries и перезапуск контейнера...${NC}"
POSTGRES_CONTAINER_ID=$(docker ps -qf "ancestor=postgres-timescaledb:17")
if [ -z "$POSTGRES_CONTAINER_ID" ]; then
    echo -e "${RED}Ошибка: контейнер PostgreSQL не найден.${NC}"
    exit 1
fi

docker exec -it "$POSTGRES_CONTAINER_ID" bash -c "echo "shared_preload_libraries = 'timescaledb'" >> /var/lib/postgresql/data/postgresql.conf"
docker restart "$POSTGRES_CONTAINER_ID"
check_error
echo -e "${GREEN}Контейнер PostgreSQL перезапущен.${NC}"

# Шаг 9: Настройка TimescaleDB
echo -e "${GREEN}Настройка TimescaleDB в PostgreSQL...${NC}"
docker exec -it "$POSTGRES_CONTAINER_ID" psql -U zabbix -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
check_error

docker exec -it "$POSTGRES_CONTAINER_ID" psql -U zabbix -c "SELECT create_hypertable('history', 'clock', migrate_data => true, if_not_exists => true);"
check_error

docker exec -it "$POSTGRES_CONTAINER_ID" psql -U zabbix -c "SELECT create_hypertable('trends', 'clock', migrate_data => true, if_not_exists => true);"
check_error
echo -e "${GREEN}TimescaleDB успешно настроен.${NC}"

# Шаг 10: Финальное сообщение
echo -e "${GREEN}Установка завершена! Zabbix доступен по адресу http://<ваш_IP>.${NC}"
