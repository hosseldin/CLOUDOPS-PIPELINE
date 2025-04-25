#!/bin/bash
# Start Docker daemon in background
sudo dockerd > /tmp/dockerd.log 2>&1 &

# Give it a few seconds to start up
sleep 5

# Run the Jenkins agent
exec /usr/bin/tini -- /usr/local/bin/jenkins-agent
