# Fullstack Test App

> **Experimental.** This is a demo application built for a conference presentation. Not production-ready and may have bugs.

Full-stack demo application used as an agent target for [tsk](https://github.com/Myradose/tsk) environments. During the live demo, three parallel agents each implement a different UI approach (tabs, accordions, side-nav) in this app while the audience watches via [Pocket Manager](https://github.com/Myradose/pocket-manager).

## Stack

- **Frontend:** Angular 20 (standalone components)
- **Backend:** Two .NET 8 Web APIs (UserApi, ProductApi)
- **Database:** SQL Server 2022
- **Gateway:** Nginx reverse proxy

## Architecture

```
Angular UI (:4200) --> Nginx Gateway (:8000)
                          |
                +---------+---------+
                |                   |
          UserApi (:5000)    ProductApi (:5001)
                |                   |
                +------- SQL -------+
                      Server
                      (:1433)
```

The gateway routes `/api/users/*` to UserApi and `/api/products/*` to ProductApi. The Angular frontend talks only to the gateway.

## Running

```bash
docker compose up -d           # Start all services
docker compose logs -f         # Stream logs
docker compose restart <svc>   # Restart a service
```

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| Angular UI | 4200 | http://localhost:4200 |
| API Gateway | 8000 | http://localhost:8000 |
| UserApi | 5000 | http://localhost:5000 |
| ProductApi | 5001 | http://localhost:5001 |
| SQL Server | 1433 | -- |

## Key Locations

| Path | Purpose |
|------|---------|
| `ui/` | Angular frontend |
| `ui/src/app/components/` | UI components |
| `ui/src/app/services/` | API services |
| `api/UserApi/` | User API (.NET 8) |
| `api/ProductApi/` | Product API (.NET 8) |
| `db/init/` | Database initialization scripts |
| `nginx.conf` | Gateway routing configuration |
| `docker-compose.yml` | Service orchestration |
