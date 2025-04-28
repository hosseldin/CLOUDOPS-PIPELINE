# Use official Jenkins image as base
FROM jenkins/jenkins:lts-jdk17

# Switch to root to install packages
USER root

# Install prerequisites
RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip \
    sudo \
    software-properties-common \
    gnupg2 \
    apt-transport-https \
    ca-certificates \
    lsb-release

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Create docker group and add Jenkins user to it
RUN groupadd -f docker && \
    usermod -aG jenkins

# Setup docker socket directory
RUN mkdir -p /var/run && \
    chmod 755 /var/run

# Switch back to jenkins user
USER jenkins

# Verify installations
RUN docker --version && \
    aws --version