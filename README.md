# Fullstack Test App

A complete fullstack application for testing TSK's serve mode functionality. This application mimics a real production stack with Angular frontend, ASP.NET Core APIs, SQL Server database, and nginx reverse proxy.

## Purpose

This repository is designed for testing TSK's serve mode features, particularly:
- Long-running containers with persistent state
- Docker-in-Docker capabilities with sysbox-runc
- Multiple parallel implementations ("Doctor Strange" workflow)
- Live development with hot reload
- Traefik routing for accessing multiple serve containers

## Architecture

```
Angular Frontend (Port 4200)
    ↓
nginx API Gateway (Port 8000)
    ├─ UserApi (Port 5000)
    └─ ProductApi (Port 5001)
    ↓
SQL Server Database (Port 1433)
```

## Repository Structure

This is a **git superproject with submodules**:
- `ui/` - Angular 20 frontend (submodule)
- `api/` - ASP.NET Core 8.0 APIs (submodule)
- `db/` - SQL Server database initialization (submodule)
- `docker-compose.yml` - Orchestration for all services
- `nginx.conf` - API gateway configuration
- `.tsk/dockerfiles/project/` - TSK agent environment customization

## Tech Stack

- **Frontend**: Angular 20 with standalone components
- **Backend**: ASP.NET Core 8.0 with Entity Framework Core
- **Database**: SQL Server 2022
- **Gateway**: nginx reverse proxy
- **Orchestration**: Docker Compose
- **AI Agent**: Claude Code CLI

## Using with TSK Serve Mode

### Prerequisites

1. **Install sysbox-runc** (for Docker-in-Docker):
   ```bash
   # Installation instructions: https://github.com/nestybox/sysbox
   ```

2. **Generate Docker image tar files** (REQUIRED - not in git due to size):
   ```bash
   cd /home/alden/projects/fullstack-test-app

   # Pull and save images (run on your HOST, not in container)
   docker pull mcr.microsoft.com/dotnet/sdk:8.0
   docker save mcr.microsoft.com/dotnet/sdk:8.0 -o docker-images/dotnet-sdk-8.0.tar

   docker pull node:lts-alpine
   docker save node:lts-alpine -o docker-images/node-lts-alpine.tar

   docker pull mcr.microsoft.com/mssql/server:2022-latest
   docker save mcr.microsoft.com/mssql/server:2022-latest -o docker-images/mssql-2022.tar

   docker pull nginx:alpine
   docker save nginx:alpine -o docker-images/nginx-alpine.tar

   # These files (~2.6GB) are excluded from git but needed for network-restricted containers
   ```

3. **Build TSK Docker images**:
   ```bash
   # First build the project-specific image from fullstack-test-app directory
   cd /home/alden/projects/fullstack-test-app
   tsk docker build

   # This includes the pre-saved Docker images in the project layer
   # The image will be cached and reused for all serve containers
   ```

### Phase 1: Basic Serve Mode

**Test 1: Start a serving container**
```bash
cd /home/alden/projects/fullstack-test-app
tsk shell --serve --runtime sysbox-runc --name fullstack-dev-1
```

Inside the container:
```bash
# Start all services
docker-compose up -d

# Check services are running
docker ps

# Make code changes to any submodule (ui, api, db)
cd ui
# ... edit files ...
git add .
git commit -m "feat: add new feature"

# Exit container (it keeps running)
exit
```

**Test 2: List and manage serving containers**
```bash
# List all serving containers
tsk serve list

# View logs
tsk serve logs fullstack-dev-1

# Reattach to container
tsk serve attach fullstack-dev-1

# Stop container
tsk serve stop fullstack-dev-1
```

### Phase 2-3: Multiple Parallel Implementations

**Start multiple implementations**
```bash
# Implementation A: Tabs
tsk shell --serve --runtime sysbox-runc --name tabs-implementation
# Inside: make changes, docker-compose up, exit

# Implementation B: Accordions
tsk shell --serve --runtime sysbox-runc --name accordions-implementation
# Inside: make changes, docker-compose up, exit

# Implementation C: Carousel
tsk shell --serve --runtime sysbox-runc --name carousel-implementation
# Inside: make changes, docker-compose up, exit
```

**Access via Traefik** (Phase 3, after Traefik setup):
- http://tabs-implementation.localhost:8080
- http://accordions-implementation.localhost:8080
- http://carousel-implementation.localhost:8080

### Phase 5: Visual Feedback with VNC

After VNC setup, access visual interfaces:
- http://tabs-implementation.localhost:8080/vnc
- http://accordions-implementation.localhost:8080/vnc
- http://carousel-implementation.localhost:8080/vnc

## Running Without TSK (Standard Docker Compose)

```bash
# Start all services
docker-compose up -d

# Access application
open http://localhost:4200

# View API gateway health
curl http://localhost:8000/health

# Stop all services
docker-compose down
```

## API Endpoints

All API requests go through nginx gateway at `http://localhost:8000`:

### Users API
- `GET /api/users` - List all users
- `GET /api/users/{id}` - Get user by ID
- `POST /api/users` - Create user
- `PUT /api/users/{id}` - Update user
- `DELETE /api/users/{id}` - Delete user

### Products API
- `GET /api/products` - List all products
- `GET /api/products/{id}` - Get product by ID
- `POST /api/products` - Create product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product

## Development Workflow

### Making Changes in Serve Mode

1. **Start serve container**: `tsk shell --serve --runtime sysbox-runc`
2. **Start services inside**: `docker-compose up -d`
3. **Make changes**: Edit files in `ui/`, `api/`, or `db/` submodules
4. **Commit changes**: Use git in each submodule
5. **Test changes**: Services auto-reload (Angular, .NET with hot reload)
6. **Exit**: Type `exit` (container keeps running)
7. **Review results**: TSK will fetch changes from all submodules

### Git Submodules

TSK has **full submodule support**:
- Changes in any submodule are committed independently
- TSK fetches branches from all repos with changes
- Each repo gets a branch like `tsk/feat/feature-name/abc123`

## Custom TSK Configuration

### Project Dockerfile

Located at `.tsk/dockerfiles/project/fullstack-test-app.dockerfile`, this customizes the agent environment with:
- Docker + Docker Compose (for Docker-in-Docker)
- .NET 8.0 SDK (for ASP.NET Core APIs)
- Angular CLI (for frontend development)
- SQL Server tools (for database operations)
- Pre-saved Docker images (copied to `/opt/docker-images/` during build)

Built automatically by TSK on top of:
- Base layer: Ubuntu 24.04 + common tools
- Stack layer: Node.js + npm (default)
- Agent layer: Claude Code CLI

**Runtime Configuration:**
- Container runs as **root** when using sysbox-runc (required for Docker-in-Docker)
- All tools installed system-wide or to /root for root user access
- Sysbox provides namespace isolation, so root inside ≠ root on host (safe)

**Important**: The Docker images (*.tar files) are copied from the fullstack-test-app directory into the Docker image during build. This is why you must run `tsk docker build` from this directory before using serve mode. The images are gitignored but baked into the Docker layer, making them available in all containers without needing network access.

## Requirements

- **TSK**: Latest version with serve mode support
- **Docker**: With Docker Compose plugin
- **Sysbox**: For Docker-in-Docker support
- **Git**: For submodule management

## Troubleshooting

**Container won't start with sysbox-runc:**
```bash
# Verify sysbox is installed
docker run --rm --runtime sysbox-runc alpine echo "sysbox works"
```

**Services won't start inside container:**
```bash
# Inside serve container, check Docker daemon
docker ps
# If error, Docker-in-Docker may not be working (check sysbox)
```

**Submodule changes not fetched:**
```bash
# TSK automatically fetches from all submodules with changes
# If issues, check .git/modules/ directory exists in task copy
```

## References

- [TSK Documentation](/home/alden/projects/tsk/README.md)
- [Serve Mode Feature Plan](/home/alden/projects/tsk/docs/serve-mode-feature-plan.md)
- [Serve Mode Testing Guide](/home/alden/projects/tsk/docs/serve-mode-testing-guide.md)
- [Sysbox Documentation](https://github.com/nestybox/sysbox)
