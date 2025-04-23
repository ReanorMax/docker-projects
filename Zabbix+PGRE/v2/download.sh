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

# Шаг 1: Переход в директорию /root/offline-install
INSTALL_DIR="/root/offline-install"
echo -e "${GREEN}Переход в директорию: ${INSTALL_DIR}${NC}"
cd "$INSTALL_DIR" || { echo -e "${RED}Не удалось перейти в директорию ${INSTALL_DIR}${NC}"; exit 1; }

# Шаг 2: Установка зависимостей (curl)
echo -e "${GREEN}Установка зависимостей (curl)...${NC}"
apt-get update
apt-get install -y curl
check_error

# Шаг 3: Создание поддиректории docker-images (если её нет)
DOCKER_IMAGES_DIR="$INSTALL_DIR/docker-images"
echo -e "${GREEN}Создание поддиректории для Docker-образов: ${DOCKER_IMAGES_DIR}${NC}"
mkdir -p "$DOCKER_IMAGES_DIR"
cd "$DOCKER_IMAGES_DIR" || { echo -e "${RED}Не удалось перейти в директорию ${DOCKER_IMAGES_DIR}${NC}"; exit 1; }

# Шаг 4: Скачивание образа pgAdmin
echo -e "${GREEN}Скачивание Docker-образа pgAdmin...${NC}"
docker pull dpage/pgadmin4:latest
check_error

# Сохранение образа в tar-файл
echo -e "${GREEN}Сохранение образа pgAdmin в файл pgadmin4.tar...${NC}"
docker save -o pgadmin4.tar dpage/pgadmin4:latest
check_error

# Возврат в исходную директорию
cd "$INSTALL_DIR" || { echo -e "${RED}Не удалось вернуться в директорию ${INSTALL_DIR}${NC}"; exit 1; }

# Шаг 5: Завершение
echo -e "${GREEN}Образ pgAdmin успешно скачан и сохранён в ${DOCKER_IMAGES_DIR}/pgadmin4.tar${NC}"
