#!/bin/bash

# transcribe.sh
SAMPLE_RATE=16000
FRAME_SIZE=8000

echo "Starting transcription service..."
echo "Press Ctrl+C to stop recording"

# Run the Python script with environment variables
SAMPLE_RATE=$SAMPLE_RATE FRAME_SIZE=$FRAME_SIZE python3 transcribe.py
