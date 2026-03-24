# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack demo application with Angular 20 frontend, two .NET 8 microservice APIs (UserApi, ProductApi), SQL Server 2022 database, and Nginx API gateway. The `ui/`, `api/`, and `db/` directories are git submodules from separate repos. Used as an agent target for [tsk](https://github.com/Myradose/tsk) environments.

## Architecture

```
Angular UI (:4200) --> Nginx Gateway (:8000)
                          |
                +---------+---------+
                |                   |
          UserApi (:5000)    ProductApi (:5001)
                |                   |
                +------- SQL -------+
                      Server (:1433)
```

The gateway routes `/api/users/*` to UserApi and `/api/products/*` to ProductApi. The Angular dev server proxies `/api/**` to `http://api-gateway:80` via `proxy.conf.json`.

## Commands

### Full Stack (from repo root)
```bash
docker compose up -d              # Start all services
docker compose logs -f            # Stream all logs
docker compose restart <service>  # Restart: user-api, product-api, fullstack-ui, sqlserver, api-gateway
```

### Angular UI (from `ui/`)
```bash
npm start                         # Dev server at localhost:4200 (with API proxy)
ng build                          # Production build to dist/
ng test                           # Unit tests (Karma + Jasmine, Chrome, watch mode)
ng test --no-watch --code-coverage # Single test run with coverage
ng lint                           # Lint
```

### .NET APIs (from `api/UserApi/` or `api/ProductApi/`)
```bash
dotnet build                      # Build
dotnet run                        # Run (UserApi on :5000, ProductApi on :5001)
dotnet watch run                  # Run with hot reload
```

## UI Architecture (Angular 20)

**Standalone components throughout** — no NgModules. All components use `ChangeDetectionStrategy.OnPush` with Angular Signals (`signal()`) for state management.

**Feature-based layout** under `ui/src/app/`:
- Each feature (`dashboard/`, `users/`, `products/`) is self-contained with its component, template, styles, service, and model in the same directory
- Shared SCSS partials in `ui/src/app/styles/` (imported via `@use '../styles/forms'`)

**Key patterns:**
- **Routing** (`app.routes.ts`): Root redirects to `/dashboard`. Features lazy-loaded via `loadComponent`
- **Services**: `providedIn: 'root'` singletons using `HttpClient` with relative URLs (`/api/users`, `/api/products`)
- **Forms**: Reactive forms with `FormBuilder.nonNullable.group()` and Validators
- **Templates**: New Angular control flow syntax (`@if`, `@for`, `@else`)
- **Accessibility**: WCAG AA — ARIA labels, semantic HTML, skip-nav link, `role` attributes

**Styling**: SCSS with component-scoped styles. No CSS framework — custom flexbox layout. Shared form/button styles in `_forms.scss`.

**TypeScript**: Strict mode with all Angular strict flags (`strictTemplates`, `strictInjectionParameters`, `strictInputAccessModifiers`, `typeCheckHostBindings`). Target ES2022.

**Build budgets**: Initial bundle 500kB warn / 1MB error. Component styles 4kB warn / 8kB error.

## Angular Material

Angular Material is set up as the UI component library for the frontend.

### First-Time Setup

To add Angular Material non-interactively, a theme must be chosen — `custom` is not a valid option (it silently falls back to `azure-blue`). Available theme palette pairs:

```bash
ng add @angular/material --skip-confirmation --theme=<theme>
```

| `--theme` value         | Primary  | Tertiary |
|-------------------------|----------|----------|
| `azure-blue` (default)  | azure    | blue     |
| `rose-red`              | rose     | red      |
| `magenta-violet`        | magenta  | violet   |
| `cyan-orange`           | cyan     | orange   |

All options generate an editable inline Sass theme in `styles.scss`. It is recommended to create a custom theme rather than keeping the defaults. Use the palette generation schematic to generate one from a brand color:

```bash
ng generate @angular/material:theme-color --help  # See all available options
```

### Schematics

Angular Material provides `ng generate` schematics for scaffolding Material-based components (e.g. `table`, `navigation`, `dashboard`, `address-form`). Run `ng generate @angular/material: --help` to see available options.

### Theming Reference

See [ui/docs/angular-material-theming.md](ui/docs/angular-material-theming.md) for the full Angular Material theming guide (Sass APIs, color palettes, light/dark mode, token overrides, etc.).

## API Architecture (.NET 8)

Both APIs share identical structure: `Controllers/`, `Models/`, `Data/` (EF Core DbContext). They use the same SQL Server database (`FullStackApp`) with separate DbContexts. No test projects exist.

**Dependencies**: EF Core 9.0.7 with SQL Server provider, Swashbuckle for Swagger (available at `/swagger` in dev).

**Connection string** (in `appsettings.json`): `Server=sqlserver,1433;Database=FullStackApp;User Id=sa;Password=Password123!;TrustServerCertificate=true;`

## Database

SQL Server 2022 with two tables: `Users` (Id, Name, Email, CreatedAt) and `Products` (Id, Name, Description, Price, CreatedAt). Initialized via `db/init/01-create-database.sql` which includes seed data.

## Infrastructure

- **TSK runtime** (`.tsk/project.toml`): Uses `sysbox-runc` for Docker-in-Docker, exposes frontend (:4200), gateway (:8000), and VNC (:6080)
- **`start-services.sh`**: Initializes VNC, Docker daemon, pulls/caches images, runs `docker compose up`
- **Nginx** (`nginx.conf`): Uses Docker DNS resolver, handles CORS headers, and provides `/health` endpoint
