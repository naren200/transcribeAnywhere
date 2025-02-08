
# Get the directory where this script resides
SCRIPT_DIR=$(dirname "$(realpath "$0")")

cd $SCRIPT_DIR

# Launch voice typing script in xterm
xterm -T "transcribe" -geometry 40x5 -bg black -fg white -e \
"/bin/bash -c \"cd $SCRIPT_DIR; ./stop_docker.sh\""
