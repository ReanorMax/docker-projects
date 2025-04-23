# 🐳 **Docker Команды** 🐳

```bash
# 🔧 Установка Docker на Ubuntu/Debian
sudo ./install_docker.sh

# 🚀 Базовые команды
docker --version          # ℹ️ Проверить версию Docker
systemctl status docker   # 🖥️ Статус службы Docker
docker run hello-world    # 🧪 Запустить тестовый контейнер

# 📦 Контейнеры
docker run <образ>        # ▶️ Запустить контейнер
docker run -it <образ> /bin/bash  # 👆 Запуск в интерактивном режиме (bash)
docker ps                 # 📋 Список запущенных контейнеров
docker ps -a              # 📜 Список всех контейнеров
docker stop <id/имя>      # ⏹️ Остановить контейнер
docker start <id/имя>     # ▶️ Запустить остановленный контейнер
docker restart <id/имя>   # 🔁 Перезапустить контейнер
docker rm <id/имя>        # 🗑️ Удалить контейнер
docker container prune    # 🧹 Удалить все остановленные контейнеры

# 🖼️ Образы
docker images             # 📸 Список образов
docker rmi <id/имя>       # 🗑️ Удалить образ
docker image prune -a     # 🧹 Удалить неиспользуемые образы
docker save -o <файл.tar> <образ>  # 💾 Сохранить образ в файл
docker load -i <файл.tar>          # 📤 Загрузить образ из файла

# 📁 Тома (Volumes)
docker volume ls          # 📂 Список томов
docker volume rm <имя>    # 🗑️ Удалить том
docker volume prune       # 🧹 Удалить неиспользуемые тома

# 🌐 Сети
docker network ls         # 🌍 Список сетей
docker network rm <имя>   # 🗑️ Удалить сеть
docker network prune      # 🧹 Удалить неиспользуемые сети

# 🧹 Полная очистка Docker
docker stop $(docker ps -aq)   # ⏹️ Остановить все контейнеры
docker rm $(docker ps -aq)     # 🗑️ Удалить все контейнеры
docker rmi $(docker images -q) # 🗑️ Удалить все образы
docker volume prune -f         # 🧹 Удалить все тома
docker network prune -f        # 🧹 Удалить все сети
sudo rm -rf /var/lib/docker    # 💥 Полная очистка (включая кэш)

# 🛠️ Дополнительные команды
docker logs <id/имя>           # 📜 Просмотр логов контейнера
docker exec -it <id/имя> <команда>  # 👨💻 Выполнить команду в контейнере
docker exec -it <id/имя> /bin/bash  # 👆 Запустить bash в контейнере

# 📌 Полезные флаги для docker run
-d          # 👻 Фоновый режим (detached)
-p 8080:80  # 🚦 Проброс портов (хост:контейнер)
--name my-app  # 🏷️ Назначить имя контейнеру
-v /host:/container  # 📦 Монтирование тома