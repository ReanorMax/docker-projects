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

# Шаг 1: Создание директории для файлов
INSTALL_DIR="/root/offline-install"
echo -e "${GREEN}Создание директории для файлов: ${INSTALL_DIR}${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || { echo -e "${RED}Не удалось перейти в директорию ${INSTALL_DIR}${NC}"; exit 1; }

# Шаг 2: Установка зависимостей (curl, gpg)
echo -e "${GREEN}Установка зависимостей (curl, gpg)...${NC}"
apt-get update
apt-get install -y curl gnupg
check_error

# Шаг 3: Добавление репозитория Docker
echo -e "${GREEN}Добавление репозитория Docker...${NC}"

# Скачивание и добавление GPG-ключа Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
check_error

# Добавление репозитория Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
check_error

# Обновление списка пакетов
apt-get update
if grep -q "NO_PUBKEY" /var/log/apt/term.log; then
    echo -e "${RED}Ошибка: GPG-ключ Docker не был добавлен. Попробуйте выполнить скрипт снова.${NC}"
    exit 1
fi
check_error

# Шаг 4: Скачивание Docker пакетов
echo -e "${GREEN}Скачивание Docker пакетов...${NC}"
mkdir -p docker-packages
cd docker-packages
apt-get download docker-ce docker-ce-cli containerd.io
check_error
cd "$INSTALL_DIR"

# Шаг 5: Установка Docker
echo -e "${GREEN}Установка Docker...${NC}"
dpkg -i docker-packages/*.deb
apt-get install -f -y
check_error

# Проверка установки Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Ошибка: Docker не установлен. Проверьте логи.${NC}"
    exit 1
fi

# Шаг 6: Скачивание Docker Compose
echo -e "${GREEN}Скачивание Docker Compose...${NC}"
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o docker-compose
chmod +x docker-compose
check_error

# Шаг 7: Скачивание Docker-образов
echo -e "${GREEN}Скачивание Docker-образов...${NC}"
mkdir -p docker-images
cd docker-images

# PostgreSQL
docker pull postgres:17
docker save -o postgres-17.tar postgres:17
check_error

# Zabbix Server
docker pull zabbix/zabbix-server-pgsql:latest
docker save -o zabbix-server-pgsql.tar zabbix/zabbix-server-pgsql:latest
check_error

# Zabbix Web
docker pull zabbix/zabbix-web-nginx-pgsql:latest
docker save -o zabbix-web-nginx-pgsql.tar zabbix/zabbix-web-nginx-pgsql:latest
check_error

# pgAdmin
docker pull dpage/pgadmin4:latest
docker save -o pgadmin4.tar dpage/pgadmin4:latest
check_error

cd "$INSTALL_DIR"

# Шаг 8: Создание файла docker-compose.yml
echo -e "${GREEN}Создание файла docker-compose.yml...${NC}"
cat <<EOF > docker-compose.yml
version: '3'
services:
  zabbix-db:
    image: postgres:17
    environment:
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: your_zabbix_password
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
    restart: always

  zabbix-server:
    image: zabbix/zabbix-server-pgsql:latest
    environment:
      DB_SERVER_HOST: zabbix-db
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: your_zabbix_password
    depends_on:
      - zabbix-db
    restart: always

  zabbix-web:
    image: zabbix/zabbix-web-nginx-pgsql:latest
    environment:
      DB_SERVER_HOST: zabbix-db
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: your_zabbix_password
      ZBX_SERVER_HOST: zabbix-server
      PHP_TZ: Europe/Moscow
    depends_on:
      - zabbix-db
      - zabbix-server
    ports:
      - "80:8080"
    restart: always

  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: MySecurePgAdminPassword123!
    ports:
      - "5050:80"
    depends_on:
      - zabbix-db
    restart: always
EOF
check_error

# Шаг 9: Завершение
echo -e "${GREEN}Все файлы успешно скачаны и сохранены в директории: ${INSTALL_DIR}${NC}"