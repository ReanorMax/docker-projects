#!/bin/bash

# 1. Проверка прав доступа
if [ "$EUID" -ne 0 ]; then
    echo "Этот скрипт должен выполняться с правами root. Используйте sudo."
    exit 1
fi

echo "=== Начало установки Docker ==="

# 2. Определение дистрибутива
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_CODENAME
else
    echo "Не удалось определить дистрибутив. Убедитесь, что файл /etc/os-release существует."
    exit 1
fi

echo "Определён дистрибутив: $OS_NAME ($OS_VERSION)"

# 3. Обновление системы
echo "=== Обновление системы ==="
apt-get update -y || { echo "Ошибка при обновлении системы"; exit 1; }

# 4. Установка зависимостей
echo "=== Установка зависимостей ==="
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || { echo "Ошибка при установке зависимостей"; exit 1; }

# 5. Добавление GPG-ключа Docker
echo "=== Добавление GPG-ключа Docker ==="
curl -fsSL https://download.docker.com/linux/$OS_NAME/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || { echo "Ошибка при добавлении GPG-ключа Docker"; exit 1; }

# 6. Добавление репозитория Docker
echo "=== Добавление репозитория Docker ==="
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_NAME $OS_VERSION stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Ошибка при добавлении репозитория Docker"; exit 1; }

# 7. Обновление списка пакетов
echo "=== Обновление списка пакетов ==="
apt-get update -y || { echo "Ошибка при обновлении списка пакетов"; exit 1; }

# 8. Установка Docker
echo "=== Установка Docker ==="
apt-get install -y docker-ce docker-ce-cli containerd.io || { echo "Ошибка при установке Docker"; exit 1; }

# 9. Запуск и включение Docker-сервиса
echo "=== Запуск Docker ==="
systemctl start docker || { echo "Ошибка при запуске Docker"; exit 1; }
systemctl enable docker || { echo "Ошибка при включении Docker"; exit 1; }

# 10. Проверка установки Docker
echo "=== Проверка установки Docker ==="
docker --version || { echo "Docker не установлен или не работает"; exit 1; }

# 11. Добавление текущего пользователя в группу docker (опционально)
echo "=== Добавление текущего пользователя в группу docker ==="
usermod -aG docker $(whoami) || { echo "Ошибка при добавлении пользователя в группу docker"; exit 1; }

echo "=== Docker успешно установлен ==="
echo "Чтобы применить изменения группы, перезагрузите систему или выполните 'newgrp docker'."

exit 0