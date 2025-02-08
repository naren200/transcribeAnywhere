#!/bin/bash

# Get the directory where this script resides
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Automatically set ROS workspace to the script's parent directory
export LOCAL_WS="$SCRIPT_DIR"

export AUDIO_GID=$(getent group audio | cut -d: -f3)

# Parse arguments
for arg in "$@"; do
  if [[ $arg == --capture=* ]]; then
    CAPTURE_DEVICE="${arg#*=}"
    echo "Capture device set to: $CAPTURE_DEVICE"
  fi
done

# Set defaults if not specified
export CAPTURE_DEVICE=${CAPTURE_DEVICE:-2}

# Default developer mode
DEVELOPER="False"

# Parse all arguments
for arg in "$@"; do
  if [[ $arg == --developer=* ]]; then
    value="${arg#*=}"
    lower_value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
    
    if [[ $lower_value == "true" ]]; then
      DEVELOPER="True"
      echo "Developer mode enabled: Docker images will just be attached"
    elif [[ $lower_value == "false" ]]; then
      DEVELOPER="False"
      echo "Developer mode disabled"
    else
      echo "Invalid developer value: $value. Using default: False"
    fi
  fi
done

export DEVELOPER=${DEVELOPER:-false}
echo "Developer mode status: $DEVELOPER"


docker compose -f docker-compose.yml up -d $BUILD_MODE type_node --remove-orphans

# Allow local connections to the X server
xhost +local:docker

echo "waiting..."
# docker compose logs

# Adjust the sleep time as necessary based on your container's startup time
sleep 2

echo "connecting..."

# Open a terminal session inside the container
./connect_to_single_docker.sh

