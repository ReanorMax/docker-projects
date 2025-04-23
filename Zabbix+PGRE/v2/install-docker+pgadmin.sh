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
for image in "$DOCKER_IMAGES_DIR"/*.tar; do
    docker load -i "$image"
    check_error
done
echo -e "${GREEN}Docker-образы успешно загружены.${NC}"

# Шаг 6: Запуск контейнеров
echo -e "${GREEN}Запуск контейнеров через docker-compose...${NC}"
cd "$INSTALL_DIR" || exit 1
docker-compose down
docker-compose up -d
check_error
echo -e "${GREEN}Контейнеры успешно запущены.${NC}"

# Шаг 7: Финальное сообщение
echo -e "${GREEN}Установка завершена!${NC}"
echo -e "${GREEN}Zabbix доступен по адресу http://<ваш_IP>.${NC}"
echo -e "${GREEN}pgAdmin доступен по адресу http://<ваш_IP>:5050.${NC}"
echo -e "${GREEN}Логин: admin@example.com, Пароль: admin_password${NC}"