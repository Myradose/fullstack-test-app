# Docker Images for Fullstack Test App

This directory contains Docker image tar files used by docker-compose. These images are pre-saved to avoid network downloads when running inside TSK serve containers (which have proxy restrictions).

## Images Included

- `dotnet-sdk-8.0.tar` - .NET SDK 8.0 (820MB) - for UserApi and ProductApi
- `node-lts-alpine.tar` - Node.js LTS Alpine (156MB) - for Angular frontend
- `mssql-2022.tar` - SQL Server 2022 (1.6GB) - for database
- `nginx-alpine.tar` - nginx Alpine (53MB) - for API gateway

**Total size: ~2.6GB**

## Loading Images in Serve Container

When running `tsk shell --serve --runtime sysbox-runc`, load these images before running docker-compose:

```bash
# Inside the container
docker load -i docker-images/dotnet-sdk-8.0.tar
docker load -i docker-images/node-lts-alpine.tar
docker load -i docker-images/mssql-2022.tar
docker load -i docker-images/nginx-alpine.tar

# Verify images are loaded
docker images

# Now docker-compose will use these images instead of pulling
docker-compose up -d
```

## Recreating These Files

If you need to regenerate these tar files (on your host machine):

```bash
# Pull each image
docker pull mcr.microsoft.com/dotnet/sdk:8.0
docker pull node:lts-alpine
docker pull mcr.microsoft.com/mssql/server:2022-latest
docker pull nginx:alpine

# Save each as a tar file
docker save mcr.microsoft.com/dotnet/sdk:8.0 -o docker-images/dotnet-sdk-8.0.tar
docker save node:lts-alpine -o docker-images/node-lts-alpine.tar
docker save mcr.microsoft.com/mssql/server:2022-latest -o docker-images/mssql-2022.tar
docker save nginx:alpine -o docker-images/nginx-alpine.tar
```

## Phase 2 Init Script

In Phase 2, this will be automated with an init script in `.tsk/serve.toml`:

```toml
[serve]
init_script = """
  docker load -i docker-images/dotnet-sdk-8.0.tar
  docker load -i docker-images/node-lts-alpine.tar
  docker load -i docker-images/mssql-2022.tar
  docker load -i docker-images/nginx-alpine.tar
  docker-compose up -d
"""
```

## Why This Approach?

TSK serve containers use a proxy for network access, which can be slow. By pre-saving Docker images as tar files in the repository, they're available locally and can be loaded quickly without network access.
