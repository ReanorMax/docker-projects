#!/bin/bash

# 1. Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo "Docker не установлен. Установите Docker перед выполнением скрипта."
    exit 1
fi

# 2. Очистка всех Docker-данных
echo "=== Очистка всех Docker-данных ==="

# Остановка всех запущенных контейнеров
echo "Остановка всех контейнеров..."
docker stop $(docker ps -aq) || true

# Удаление всех контейнеров
echo "Удаление всех контейнеров..."
docker rm $(docker ps -aq) || true

# Удаление всех образов
echo "Удаление всех образов..."
docker rmi $(docker images -q) || true

# Удаление всех томов
echo "Удаление всех томов..."
docker volume prune -f || true

# Удаление всех сетей
echo "Удаление всех сетей..."
docker network prune -f || true

# Полная очистка Docker (опционально)
echo "Полная очистка Docker (удаление /var/lib/docker)..."
sudo rm -rf /var/lib/docker || true

# Перезапуск Docker-сервиса
echo "Перезапуск Docker-сервиса..."
sudo systemctl restart docker

# 3. Очистка кэша Docker
echo "=== Очистка кэша Docker ==="
docker builder prune --all -f || { echo "Ошибка при очистке кэша Docker"; exit 1; }

# 4. Создание временной директории
WORKDIR=$(mktemp -d)
echo "=== Временная директория: $WORKDIR ==="

# 5. Создание Dockerfile
echo "=== Создание Dockerfile ==="
cat <<EOF > "$WORKDIR/Dockerfile"
FROM centos:7

# Настройка Vault-репозитория
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Base.repo

# Обновление системы и установка необходимых утилит
RUN yum update -y && \
    yum install -y nano wget curl git vim net-tools glibc-common && \
    yum clean all

# Настройка локалей
RUN localedef -c -f UTF-8 -i en_US en_US.UTF-8 && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    export LANG=en_US.UTF-8

# Установка рабочей директории
WORKDIR /root

# Команда по умолчанию
CMD ["/bin/bash"]
EOF

# 6. Сборка нового образа
echo "=== Сборка нового образа CentOS ==="
docker build -t my-centos "$WORKDIR"

# Проверка успешности сборки
if [ $? -ne 0 ]; then
    echo "=== Ошибка при сборке образа ==="
    rm -rf "$WORKDIR"
    exit 1
fi

# 7. Удаление временной директории
echo "=== Удаление временной директории ==="
rm -rf "$WORKDIR"

# 8. Запуск контейнера из нового образа
echo "=== Запуск контейнера из нового образа ==="
docker run -it --name my-centos-container my-centos

# Проверка успешности запуска
if [ $? -ne 0 ]; then
    echo "=== Ошибка при запуске контейнера ==="
    exit 1
fi

echo "=== Все операции завершены успешно ==="