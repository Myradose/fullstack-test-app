# Fullstack Test App

> **Experimental.** This is a demo application built for a conference presentation. Not production-ready.

Full-stack demo application used as a target for [tsk](https://github.com/Myradose/tsk) agent environments. During the live demo, three parallel agents each implement a different UI approach (tabs, accordions, side-nav) in this app.

## Stack

- **Frontend:** Angular 20 (standalone components)
- **Backend:** Two .NET 8 Web APIs (UserApi, ProductApi)
- **Database:** SQL Server 2022
- **Gateway:** Nginx reverse proxy

## Running

```bash
docker compose up -d
```

## Key Locations

| Path | Purpose |
|------|---------|
| `ui/` | Angular frontend |
| `api/UserApi/` | User API (.NET 8) |
| `api/ProductApi/` | Product API (.NET 8) |
| `db/init/` | Database initialization scripts |
| `nginx.conf` | API gateway configuration |
| `docker-compose.yml` | Service orchestration |
