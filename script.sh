#!/bin/bash

FLASK_IMAGE="flask-app-task"
NETWORK_NAME="f-a-network"
POSTGRES_CONTAINER="pg_db_container"
FLASK_CONTAINER="flask_app_container"

POSTGRES_USER="postgres"
POSTGRES_PASSWORD="postgres"
POSTGRES_DB="users_db"

# Создание сети, если она не существует
if ! docker network inspect "$NETWORK_NAME" &>/dev/null; then
    echo "Создаём Docker сеть: $NETWORK_NAME"
    docker network create "$NETWORK_NAME"
fi

# Создание томов для данных и логов
echo "Создаём тома для данных..."
docker volume create pgdata
docker volume create applogs

# Запуск PostgreSQL контейнера
if ! docker ps -a --format '{{.Names}}' | grep -qw "$POSTGRES_CONTAINER"; then
    echo "Запуск PostgreSQL контейнера..."
    docker run -d \
        --name "$POSTGRES_CONTAINER" \
        --network "$NETWORK_NAME" \
        -e POSTGRES_USER="$POSTGRES_USER" \
        -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        -e POSTGRES_DB="$POSTGRES_DB" \
        -v pgdata:/var/lib/postgresql/data \
        -v "$(pwd)/init_db.sql:/docker-entrypoint-initdb.d/init_db.sql" \
        -p 5432:5432 \
        postgres:latest
    sleep 3
    docker exec -i pg_db_container psql -U postgres -d users_db -f /docker-entrypoint-initdb.d/init_db.sql & > /dev/null
else
    echo "PostgreSQL контейнер уже существует. Запускаем..."
    docker start "$POSTGRES_CONTAINER"
fi

# Сборка Flask образа
echo "Сборка Docker образа Flask приложения..."
docker build --no-cache=True -t "$FLASK_IMAGE" .

# Запуск Flask контейнера
if ! docker ps -a --format '{{.Names}}' | grep -qw "$FLASK_CONTAINER"; then
    echo "Запуск Flask контейнера..."
    docker run -d \
        --name "$FLASK_CONTAINER" \
        --network "$NETWORK_NAME" \
        -p 5000:5000 \
        -v applogs:/app/logs \
        --env-file .env \
        "$FLASK_IMAGE"
else
    echo "Flask контейнер уже существует. Запускаем..."
    docker start "$FLASK_CONTAINER"
fi

echo "Все контейнеры запущены!"
