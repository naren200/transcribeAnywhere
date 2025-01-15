#!/bin/bash
set -x  # Enable debug mode to print commands as they execute

WHISPER_PATH="/app/whisper.cpp"
MODEL_PATH="$WHISPER_PATH/models/ggml-base.en.bin"
TEMP_DIR="/tmp"
TEMP_WAV="$TEMP_DIR/recording.wav"

# Verify paths exist
echo "Checking paths..."
ls -l $WHISPER_PATH
ls -l $MODEL_PATH

# Test YAD installation
echo "Testing YAD..."
yad --version

# Test audio device
echo "Testing audio device..."
arecord -l

# Create floating button using yad
while true; do
    echo "Starting YAD notification..."
    yad --notification \
        --image="audio-input-microphone" \
        --command="echo 'recording'" \
        --text="Click to Record" \
        --no-middle

    if [ $? -eq 0 ]; then
        echo "Button clicked - starting recording"
        # Start recording
        echo "Recording... Click the button again to stop"
        sox -d -r 16000 -c 1 -b 16 "$TEMP_WAV" &
        SOX_PID=$!
        echo "Recording PID: $SOX_PID"

        # Wait for button click to stop recording
        echo "Waiting for stop button click..."
        yad --notification \
            --image="media-playback-stop" \
            --command="echo 'stop'" \
            --text="Recording... Click to Stop"
        
        echo "Stop button clicked"
        # Stop recording
        kill $SOX_PID
        
        # Verify recording exists
        echo "Checking recording file..."
        ls -l "$TEMP_WAV"
        
        # Transcribe and paste at cursor location
        echo "Starting transcription..."
        cd $WHISPER_PATH/build/bin
        ./main -m $MODEL_PATH -f "$TEMP_WAV" -otxt 2>/dev/null | tee >(xsel -ib) | while read line; do
            echo "Transcribed line: $line"
            xdotool type "$line"
            xdotool key Return
        done

        # Cleanup
        echo "Cleaning up..."
        rm "$TEMP_WAV"
    fi
done
