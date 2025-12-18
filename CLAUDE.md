# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack demo application with microservices architecture:
- **Frontend**: Angular 20 (standalone components, no NgModules)
- **Backend**: Two .NET 8.0 Web APIs (UserApi, ProductApi)
- **Database**: SQL Server 2022
- **Gateway**: Nginx reverse proxy handling CORS and routing

## Common Commands

### Start all services
```bash
docker compose up -d
```

### View logs
```bash
docker compose logs -f              # All services
docker compose logs -f user-api     # UserApi only
docker compose logs -f product-api  # ProductApi only
docker compose logs -f fullstack-ui # Angular UI only
```

### Restart a service
```bash
docker compose restart user-api
```

### Run commands inside containers (if needed)
```bash
docker compose exec user-api dotnet build
docker compose exec fullstack-ui npm test
```

**Important**: Never run interactive commands (e.g., `dotnet watch`, `ng serve` without docker). All services run in containers via docker compose.

## Architecture

```
┌─────────────────┐     ┌──────────────────────────────────┐
│  Angular UI     │────▶│  Nginx Gateway (:8000)           │
│  (:4200)        │     │  /api/users/* → UserApi          │
└─────────────────┘     │  /api/products/* → ProductApi    │
                        └──────────┬───────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
            ┌───────────────┐            ┌───────────────┐
            │  UserApi      │            │  ProductApi   │
            │  (:5000)      │            │  (:5001)      │
            └───────┬───────┘            └───────┬───────┘
                    │                            │
                    └──────────┬─────────────────┘
                               ▼
                    ┌───────────────────┐
                    │  SQL Server       │
                    │  (:1433)          │
                    └───────────────────┘
```

## Key File Locations

| Component | Location |
|-----------|----------|
| Angular app entry | `ui/src/main.ts` |
| Angular config | `ui/src/app/app.config.ts` |
| Angular components | `ui/src/app/components/` |
| Angular services | `ui/src/app/services/` |
| UserApi entry | `api/UserApi/Program.cs` |
| ProductApi entry | `api/ProductApi/Program.cs` |
| DB init scripts | `db/init/` |
| Gateway config | `nginx.conf` |

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| Angular UI | 4200 | http://localhost:4200 |
| API Gateway | 8000 | http://localhost:8000 |
| UserApi | 5000 | http://localhost:5000 |
| ProductApi | 5001 | http://localhost:5001 |
| SQL Server | 1433 | - |
| Swagger (UserApi) | - | http://localhost:5000/swagger |
| Swagger (ProductApi) | - | http://localhost:5001/swagger |

## Database

- **Connection string**: `Server=localhost,1433;Database=FullStackApp;User Id=sa;Password=Password123!;TrustServerCertificate=true;`
- **Tables**: `Users` (Id, Name, Email, CreatedAt), `Products` (Id, Name, Description, Price, CreatedAt)
