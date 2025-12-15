# Project-specific Dockerfile for fullstack-test-app
# Builds on tsk's node stack (already has Ubuntu 24.04, Node.js, npm, Claude Code CLI)
# Adds: Docker, .NET SDK, Angular CLI, SQL Server tools

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Install Docker and Docker Compose for Docker-in-Docker with sysbox
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install .NET 8.0 SDK for ASP.NET Core APIs
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 && \
    echo 'export PATH="$PATH:$HOME/.dotnet"' >> /root/.bashrc && \
    echo 'export DOTNET_ROOT="$HOME/.dotnet"' >> /root/.bashrc

ENV PATH="$PATH:/root/.dotnet"
ENV DOTNET_ROOT="/root/.dotnet"

# Install SQL Server tools for database operations
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/24.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /root/.bashrc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Install Angular CLI globally
RUN npm install -g @angular/cli @angular/language-server

WORKDIR /workspace
