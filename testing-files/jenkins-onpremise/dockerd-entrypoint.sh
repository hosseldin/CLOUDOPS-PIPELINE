#!/bin/bash
set -e

# Start Docker daemon in background
dockerd &

# Wait for Docker to be ready
while(! docker info > /dev/null 2>&1); do
  echo "Waiting for Docker to launch..."
  sleep 1
done

# Start Jenkins agent
exec /usr/bin/jenkins-agent "$@"

