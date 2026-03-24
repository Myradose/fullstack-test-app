#!/bin/bash
# Startup script for fullstack services in TSK serve container
# Uses registry-based image caching for fast parallel container startup

echo "==================================="
echo "Fullstack Services Startup Script"
echo "==================================="
echo ""

# Start VNC server for browser observability
echo "Starting VNC server for browser observability..."
Xvfb :99 -screen 0 960x1080x24 > /tmp/xvfb.log 2>&1 &
export DISPLAY=:99
sleep 1

x11vnc -display :99 -forever -nopw -shared -viewonly > /tmp/x11vnc.log 2>&1 &
sleep 1

websockify --web /usr/share/novnc 6080 localhost:5900 > /tmp/novnc.log 2>&1 &
echo "VNC server started"
echo "  Access via: /vnc/vnc.html?path=vnc/websockify&autoconnect=true&resize=scale"
echo "  DISPLAY=:99 is available for headful browser testing"
echo ""

# Start Docker-in-Docker daemon (requires sysbox-runc runtime)
# Note: TSK automatically configures Docker daemon to trust the TSK registry
echo "Starting Docker daemon..."
sudo dockerd > /tmp/dockerd.log 2>&1 &
DOCKERD_PID=$!

echo "Waiting for Docker daemon to be ready..."
for i in {1..30}; do
  if docker info > /dev/null 2>&1; then
    echo "Docker daemon is ready!"
    break
  fi

  if ! kill -0 $DOCKERD_PID 2>/dev/null; then
    echo "WARNING: Docker daemon failed to start (requires sysbox-runc runtime)"
    exit 0
  fi

  if [ $i -eq 30 ]; then
    echo "WARNING: Docker daemon timed out after 30 seconds"
    echo "  Check logs: cat /tmp/dockerd.log"
    exit 0
  fi
  sleep 1
done

# From this point on, fail on any error
set -e

cd /workspace

# ============================================================
# Registry-based image caching
#   Pull from tsk-registry if available, otherwise pull from
#   upstream. Push to registry after pull/build so subsequent
#   containers get layer-level dedup.
# ============================================================

# registry_pull: try to pull an image from the TSK registry
registry_pull() {
  local local_tag="$1"
  local registry_tag="$TSK_REGISTRY/$local_tag"
  if docker pull "$registry_tag" 2>/dev/null; then
    docker tag "$registry_tag" "$local_tag"
    return 0
  fi
  return 1
}

# registry_push: push an image to the TSK registry
registry_push() {
  local local_tag="$1"
  local registry_tag="$TSK_REGISTRY/$local_tag"
  docker tag "$local_tag" "$registry_tag"
  docker push "$registry_tag" 2>/dev/null || echo "  Warning: failed to push $local_tag to registry"
}

# Get all image names from compose config
IMAGES=$(docker compose config --images 2>/dev/null | sort -u)

echo ""
if [ -n "$TSK_REGISTRY" ]; then
  echo "Loading images via registry ($TSK_REGISTRY)..."
  for img in $IMAGES; do
    if registry_pull "$img"; then
      echo "  [cached] $img"
    else
      echo "  [miss]   $img — pulling from upstream..."
      docker pull "$img" 2>/dev/null || docker compose build --pull "$(docker compose config --services | head -1)" 2>/dev/null || true
      registry_push "$img"
    fi
  done
else
  echo "No TSK_REGISTRY — pulling images from upstream..."
  docker compose pull
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
