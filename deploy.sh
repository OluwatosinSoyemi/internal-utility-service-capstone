#!/bin/bash
set -e

IMAGE="tosinsoy/internal-utility-service:latest"
ROLLBACK_IMAGE="tosinsoy/internal-utility-service:v1.0.0"
CONTAINER="internal-app"

echo "Pulling latest image..."
if ! docker pull $IMAGE; then
    echo "New image pull failed. Keeping current container running."
    exit 1
fi

echo "Stopping and removing old container..."
docker rm -f $CONTAINER 2>/dev/null || true

echo "Starting new container..."
docker run -d \
  --name $CONTAINER \
  --restart always \
  -p 5000:5000 \
  -e SECRET_KEY="$SECRET_KEY" \
  -e APP_ENV="$APP_ENV" \
  $IMAGE

echo "Waiting for app to come up..."
sleep 10

echo "Checking application health..."
if curl -f http://localhost:5000/health; then
    echo "Deployment successful."
else
    echo "Deployment failed. Rolling back to stable image..."

    docker rm -f $CONTAINER 2>/dev/null || true

    docker run -d \
      --name $CONTAINER \
      --restart always \
      -p 5000:5000 \
      -e SECRET_KEY="$SECRET_KEY" \
      -e APP_ENV="$APP_ENV" \
      $ROLLBACK_IMAGE

    echo "Rollback completed."
    exit 1
fi
