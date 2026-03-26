# Claude agent layer - pre-cached binary (avoids network download during build)
# This eliminates the curl to claude.ai/install.sh which can fail with 429
# when GCS bandwidth quotas are exceeded.

RUN mkdir -p /home/agent/.local/bin
COPY --chown=agent:agent .tsk/claude-code /home/agent/.local/bin/claude
RUN chmod +x /home/agent/.local/bin/claude
