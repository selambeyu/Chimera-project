#!/usr/bin/env bash
# Start/stop PostgreSQL 16 in Docker for Chimera (golden environment)
# Usage: ./scripts/postgres-docker.sh up | down

CONTAINER_NAME=chimera-pg
IMAGE=postgres:16-alpine
PORT=5432
POSTGRES_USER=chimera
POSTGRES_PASSWORD=chimera_dev
POSTGRES_DB=chimera

case "${1:-}" in
    up)
        if docker ps -q -f name="^${CONTAINER_NAME}$" | grep -q .; then
            echo "PostgreSQL container already running: $CONTAINER_NAME"
            exit 0
        fi
        if docker ps -aq -f name="^${CONTAINER_NAME}$" | grep -q .; then
            docker start "$CONTAINER_NAME"
            echo "Started existing container: $CONTAINER_NAME"
        else
            docker run -d --name "$CONTAINER_NAME" \
                -e POSTGRES_USER="$POSTGRES_USER" \
                -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
                -e POSTGRES_DB="$POSTGRES_DB" \
                -p "$PORT:5432" \
                "$IMAGE"
            echo "Created and started: $CONTAINER_NAME"
        fi
        echo "DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${PORT}/${POSTGRES_DB}"
        ;;
    down)
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        echo "Stopped and removed: $CONTAINER_NAME"
        ;;
    *)
        echo "Usage: $0 up | down"
        exit 1
        ;;
esac
