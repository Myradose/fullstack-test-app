#!/bin/bash
# Startup script for fullstack services in TSK serve container
# Uses tarball-based image caching for parallel container support

echo "==================================="
echo "Fullstack Services Startup Script"
echo "==================================="
echo ""

# Start VNC server for browser observability
echo "Starting VNC server for browser observability..."
Xvfb :99 -screen 0 1920x1080x24 > /tmp/xvfb.log 2>&1 &
export DISPLAY=:99
sleep 1  # Give Xvfb time to start

x11vnc -display :99 -forever -nopw -shared -viewonly > /tmp/x11vnc.log 2>&1 &
sleep 1  # Give x11vnc time to start

# Start noVNC web interface (websockify proxies VNC to WebSocket)
websockify --web /usr/share/novnc 6080 localhost:5900 > /tmp/novnc.log 2>&1 &
echo "✓ VNC server started"
echo "  Access via: /vnc/vnc.html?path=vnc/websockify&autoconnect=true&resize=scale"
echo "  DISPLAY=:99 is available for headful browser testing"
echo ""

# Check if Docker-in-Docker is available (requires sysbox-runc runtime)
echo "Checking for Docker-in-Docker support..."
sudo dockerd > /tmp/dockerd.log 2>&1 &
DOCKERD_PID=$!

echo "Waiting for Docker daemon to be ready..."
for i in {1..30}; do
  if docker info > /dev/null 2>&1; then
    echo "✓ Docker daemon is ready!"
    break
  fi

  # Check if dockerd process is still running
  if ! kill -0 $DOCKERD_PID 2>/dev/null; then
    echo "⚠️  Docker daemon failed to start (requires sysbox-runc runtime)"
    echo "   Services will not be started."
    echo "   To use Docker-in-Docker, run with: --runtime sysbox-runc"
    exit 0  # Exit successfully, just skip services
  fi

  if [ $i -eq 30 ]; then
    echo "⚠️  Docker daemon timed out after 30 seconds"
    echo "   Check logs: cat /tmp/dockerd.log"
    kill $DOCKERD_PID 2>/dev/null || true
    exit 0  # Exit successfully, just skip services
  fi
  sleep 1
done

# From this point on, fail on any error
set -e

cd /workspace

# Image cache directory (mounted from shared volume by TSK)
IMAGE_CACHE="/docker-image-cache"
CACHE_FILE="$IMAGE_CACHE/images.tar"

echo ""
echo "Checking for cached Docker images..."
if [ -d "$IMAGE_CACHE" ] && [ -f "$CACHE_FILE" ]; then
  echo "Loading images from cache..."
  sudo docker load -i "$CACHE_FILE"
  echo "✓ Images loaded from cache"
else
  echo "Images not cached - pulling from registries..."
  docker compose pull

  # Save images to cache for next run (if cache directory exists)
  if [ -d "$IMAGE_CACHE" ]; then
    echo "Saving images to cache..."
    # Get deduplicated list of images from docker-compose.yml
    IMAGES=$(docker compose config --images | sort -u)
    sudo docker save -o "$CACHE_FILE" $IMAGES
    echo "✓ Images saved to cache"
  fi
fi

echo ""
echo "Starting services with docker compose..."
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
