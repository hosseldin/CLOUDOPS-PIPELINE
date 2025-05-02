# Use docker:dind as the base image
FROM docker:dind

# Install dependencies and AWS CLI
RUN apk add --no-cache \
    curl \
    unzip \
    python3 \
    python3-dev \
    py3-pip \
    groff \
    less \
    nano \
    sudo \
    bash \
    openjdk11-jre # Java required for Jenkins agent

# Install AWS CLI
RUN python3 -m venv /venv \
    && . /venv/bin/activate \
    && pip install --upgrade pip \
    && pip install awscli \
    && deactivate

# Optional: Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install \
    && rm -rf awscliv2.zip

# Set the ENTRYPOINT to be bash for interactive shell, but add the agent start process
ENTRYPOINT ["/bin/bash"]

# Command for Jenkins to start the agent (you might want to pass this through a command)
CMD ["java", "-jar", "/usr/share/jenkins/agent.jar", "-jnlpUrl", "http://192.168.49.2:30600/computer/<agent-name>/jenkins-agent-agent.jnlp", "-secret", "<secret-token>"]
