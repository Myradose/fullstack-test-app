# Project-specific Dockerfile for fullstack-test-app
# TSK automatically builds this on top of: base → stack (default) → agent (claude)
# This layer adds: Node.js, Docker, .NET SDK, Angular CLI, SQL Server tools

# Install Node.js and npm (needed for Angular)
USER root

# Set root password to "root" for easy su access in sysbox containers
# This is safe because sysbox isolates the container's root from the host
RUN echo 'root:root' | chpasswd

# Also configure passwordless sudo for agent user as backup
RUN echo "agent ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/agent && \
    chmod 0440 /etc/sudoers.d/agent

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Docker and Docker Compose for Docker-in-Docker with sysbox
# IMPORTANT: Pin containerd to 1.7.28-1 to avoid breaking changes in newer versions
# See: https://www.reddit.com/r/docker/comments/... (containerd bug with ip_unprivileged_port_start)
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
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io=1.7.28-1~ubuntu.24.04~noble \
        docker-buildx-plugin \
        docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add agent user to docker group so they can run dockerd without sudo
RUN usermod -aG docker agent

# Switch to agent user for installations that go to user home
USER agent

# Install .NET 8.0 SDK for ASP.NET Core APIs
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 && \
    echo 'export PATH="$PATH:$HOME/.dotnet"' >> /home/agent/.bashrc && \
    echo 'export DOTNET_ROOT="$HOME/.dotnet"' >> /home/agent/.bashrc

ENV PATH="$PATH:/home/agent/.dotnet"
ENV DOTNET_ROOT="/home/agent/.dotnet"

# Switch back to root for system-level installations
USER root

# Install SQL Server tools for database operations
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Install Angular CLI globally (as root so it's available system-wide)
RUN npm install -g @angular/cli @angular/language-server

# Switch back to agent user for runtime
USER agent
WORKDIR /workspace
