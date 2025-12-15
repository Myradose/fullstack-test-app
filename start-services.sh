#!/bin/bash
# Manual startup script for fullstack services in TSK serve container
# This will become the init_script in Phase 2

set -e  # Exit on error

echo "==================================="
echo "Fullstack Services Startup Script"
echo "==================================="
echo ""

echo "Starting Docker daemon..."
# Container runs as root with sysbox, so no sudo needed
dockerd > /tmp/dockerd.log 2>&1 &

echo "Waiting for Docker daemon to be ready..."
for i in {1..30}; do
  if docker info > /dev/null 2>&1; then
    echo "Docker daemon is ready!"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "ERROR: Docker daemon failed to start within 30 seconds"
    echo "Check logs: cat /tmp/dockerd.log"
    exit 1
  fi
  sleep 1
done

echo ""
echo "Loading Docker images from tar files..."
docker load -i /opt/docker-images/dotnet-sdk-8.0.tar
docker load -i /opt/docker-images/node-lts-alpine.tar
docker load -i /opt/docker-images/mssql-2022.tar
docker load -i /opt/docker-images/nginx-alpine.tar

echo ""
echo "Verifying images are loaded..."
docker images

echo ""
echo "Starting services with docker compose..."
cd /workspace
docker compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "Services status:"
docker ps

echo ""
echo "====================================="
echo "Fullstack services are now running!"
echo "====================================="
echo ""
echo "Test the services:"
echo "  curl http://localhost:8000/health"
echo "  curl http://localhost:4200"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo "  docker logs <container-name>"
echo ""
