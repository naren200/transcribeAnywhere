
# Get the directory where this script resides
SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd $SCRIPT_DIR
# Ensure pulseaudio is properly stopped first
pulseaudio --kill 2>/dev/null
sleep 1

# Start pulseaudio with proper environment
pulseaudio --start --log-target=syslog

# Start devilspie with config
pgrep devilspie || devilspie ~/.devilspie/transcribe.ds &

chmod +x *.sh

# Launch voice typing script in xterm  
xterm -T "transcribe" -geometry 40x5 -bg black -fg white -e \
"/bin/bash -c \"cd $SCRIPT_DIR; ./start_docker.sh --capture=3\""
