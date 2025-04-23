Zabbix Offline Installer Script
Автоматический скрипт для автономной установки Zabbix с использованием TimescaleDB.

Что делает скрипт
Проверка и распаковка архива
Проверяет наличие установочного архива offline-install.tar.gz в директории /root.
Распаковывает архив в /root/offline-install.
Установка Docker
Устанавливает Docker из локальных пакетов, находящихся в архиве.
Установка Docker Compose
Копирует и настраивает бинарный файл Docker Compose.
Загрузка Docker-образов
Загружает следующие Docker-образы:
PostgreSQL с поддержкой TimescaleDB
Zabbix Server
Zabbix Web UI (Nginx + PHP)
Настройка docker-compose.yml
Обновляет конфигурационный файл docker-compose.yml для работы с TimescaleDB.
Добавляет необходимые переменные окружения, такие как POSTGRES_INITDB_ARGS, TIMESCALEDB_TELEMETRY, и другие.
Запуск контейнеров
Запускает контейнеры через docker-compose:
PostgreSQL с TimescaleDB
Zabbix Server
Zabbix Web Interface
Настройка TimescaleDB
Добавляет параметр shared_preload_libraries = 'timescaledb' в конфигурацию PostgreSQL.
Создает расширение TimescaleDB в базе данных Zabbix.
Создает гипертаблицы для таблиц history и trends.
Завершение установки


download Script
Автоматический скрипт для подготовки всех необходимых файлов и конфигураций для автономной установки Zabbix с использованием PostgreSQL, pgAdmin и Docker.

Что делает скрипт
Создание рабочей директории
Создает директорию /root/offline-install для хранения всех скачанных файлов и конфигураций.
Установка зависимостей
Устанавливает необходимые пакеты: curl и gnupg.
Добавление репозитория Docker
Скачивает и добавляет GPG-ключ Docker.
Добавляет официальный репозиторий Docker в систему.
Обновляет список доступных пакетов.
Скачивание Docker пакетов
Скачивает следующие пакеты Docker:
docker-ce
docker-ce-cli
containerd.io
Сохраняет их в директорию docker-packages.
Установка Docker
Устанавливает Docker из скачанных пакетов.
Проверяет успешность установки Docker.
Скачивание Docker Compose
Определяет последнюю версию Docker Compose через API GitHub.
Скачивает соответствующий бинарный файл Docker Compose.
Делает файл исполняемым.
Скачивание Docker-образов
Скачивает и сохраняет следующие Docker-образы:
PostgreSQL : Версия 17 (сохраняется как postgres-17.tar).
Zabbix Server : Последняя версия на базе PostgreSQL (сохраняется как zabbix-server-pgsql.tar).
Zabbix Web : Интерфейс на базе Nginx и PostgreSQL (сохраняется как zabbix-web-nginx-pgsql.tar).
pgAdmin : Административный интерфейс для PostgreSQL (сохраняется как pgadmin4.tar).
Создание файла docker-compose.yml
Генерирует конфигурационный файл docker-compose.yml, который описывает следующие сервисы:
zabbix-db : База данных PostgreSQL с предварительно настроенной базой данных Zabbix.
zabbix-server : Сервер Zabbix, подключенный к базе данных PostgreSQL.
zabbix-web : Веб-интерфейс Zabbix, доступный на порту 80.
pgAdmin : Веб-интерфейс pgAdmin для управления PostgreSQL, доступный на порту 5050.
Завершение работы
Сообщает об успешном завершении и указывает, что все файлы сохранены в директории /root/offline-install.
Результат
После выполнения скрипта:

Все необходимые файлы для автономной установки Zabbix будут находиться в директории /root/offline-install.
Будут скачаны Docker-образы и пакеты Docker.
Будет создан файл docker-compose.yml, готовый для использования в автономной среде.
Этот скрипт позволяет подготовить все компоненты для установки Zabbix в средах без доступа к интернету.