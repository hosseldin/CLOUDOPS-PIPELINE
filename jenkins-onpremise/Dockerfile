# Dockerfile-dind-agent
FROM jenkins/inbound-agent:latest

USER root

RUN apt-get update && apt-get install -y unzip

# Install Docker
RUN apt-get update && apt-get install -y \
    docker.io \
    # docker-ce docker-ce-cli containerd.io \
    ca-certificates \
    curl \
    nano \
    unzip \
    gnupg \
    lsb-release \
    sudo
# && dockerd-entrypoint.sh &

# Add Docker’s official GPG key and setup repo
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# # Set Docker socket permissions
# RUN chmod 666 /var/run/docker.sock

# Add jenkins user to docker group and give password‑less sudo
RUN groupadd -f docker && usermod -aG docker jenkins && \
    echo 'jenkins ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/jenkins

# Start Docker inside the container
COPY dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh

USER jenkins

# Simple smoke test (ignores non‑zero exit so build doesn’t fail offline)
RUN docker --version || true && aws --version

# Final CMD (entrypoint script starts Docker and agent)
ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]