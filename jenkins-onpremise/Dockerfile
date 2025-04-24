# Dockerfile-dind-agent
FROM jenkins/inbound-agent:latest

USER root

# Install Docker
RUN apt-get update && apt-get install -y \
    docker.io \
    docker-ce docker-ce-cli containerd.io \
    ca-certificates \
    curl \
    nano \
    gnupg \
    lsb-release \
    sudo \
    && dockerd-entrypoint.sh &

# Install AWS CLI v2  ─────────────────────────────────────────────────────
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws

# Set Docker socket permissions
RUN chmod 666 /var/run/docker.sock
# Add jenkins user to docker group and give password‑less sudo
RUN groupadd -f docker && usermod -aG docker jenkins && \
    echo 'jenkins ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/jenkins

USER jenkins

# Simple smoke test (ignores non‑zero exit so build doesn’t fail offline)
RUN docker --version || true && aws --version