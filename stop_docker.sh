#!/bin/bash

# this has to be non-empty for docker-compose to run, even for down
# these don't have to be set to anything correct
export LOCAL_WS="/"

# Stop and remove the Docker Compose services
docker compose down --remove-orphans

echo "Docker Compose services stopped and removed."