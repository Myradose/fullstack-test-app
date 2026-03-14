# Project-specific Dockerfile for fullstack-test-app
# TSK automatically builds this on top of: base → stack (default) → layers (dind) → agent (claude)
# This layer adds: Node.js, .NET SDK, Angular CLI, SQL Server tools
# Docker-in-Docker is provided by the dind layer (configured via layers = ["dind"] in project.toml)

# Install Node.js and npm (needed for Angular)
USER root

# Ensure Node.js trusts system CA certs (needed behind corporate proxy)
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install .NET 8.0 SDK for ASP.NET Core APIs (as root, since container runs as root with sysbox)
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 && \
    echo 'export PATH="$PATH:$HOME/.dotnet"' >> /root/.bashrc && \
    echo 'export DOTNET_ROOT="$HOME/.dotnet"' >> /root/.bashrc

ENV PATH="$PATH:/root/.dotnet"
ENV DOTNET_ROOT="/root/.dotnet"

# Install SQL Server tools for database operations
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Install Angular CLI globally (as root so it's available system-wide)
RUN npm install -g @angular/cli@20 @angular/language-server@20

# Install beads (bd) for git-backed task tracking
# See: https://github.com/steveyegge/beads
RUN npm install -g @beads/bd

# Install beads viewer (bv) for AI-friendly graph analytics
# See: https://github.com/Dicklesworthstone/beads_viewer
RUN curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/beads_viewer/main/install.sh | bash

# Install Playwright MCP and chromium browser for browser automation
# This installs @playwright/mcp globally and downloads chromium (most common browser for testing)
# Browsers are installed to /opt/ms-playwright/ (shared location accessible by all users)
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
RUN npm install -g @playwright/mcp@latest && \
    npx playwright install --with-deps chromium && \
    chmod -R 755 /opt/ms-playwright && \
    mkdir -p /opt/playwright-profiles && \
    chown -R agent:agent /opt/playwright-profiles && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install VNC for browser observability
# Allows real-time observation of Playwright browser automation via web browser
RUN apt-get update && \
    apt-get install -y xvfb x11vnc novnc websockify && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch back to agent user so AGENT layer installs with correct ownership
# Note: sudo and docker group membership are provided by the dind layer
USER agent

# Note: Containers always run as agent user, even with sysbox-runc
# Sysbox provides Docker-in-Docker via user namespace mapping
WORKDIR /workspace
