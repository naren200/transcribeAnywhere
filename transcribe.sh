#!/bin/bash

# Configuration
SAMPLE_RATE=44100
FRAME_SIZE=8000

# Initialize recording
echo "Starting transcription service..."
echo "Press Ctrl+C to stop recording"

# Record and transcribe
python3 - << EOF
import queue
import sys
import sounddevice as sd
import vosk
import json
from subprocess import Popen, PIPE

# Initialize Vosk model
model = vosk.Model("/app/model/model")
q = queue.Queue()

def callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    q.put(bytes(indata))

try:
    with sd.RawInputStream(samplerate=$SAMPLE_RATE, blocksize=$FRAME_SIZE,
            dtype='int16', channels=1, callback=callback):
        rec = vosk.KaldiRecognizer(model, $SAMPLE_RATE)
        while True:
            data = q.get()
            if rec.AcceptWaveform(data):
                result = json.loads(rec.Result())
                if result["text"]:
                    print(result["text"])
                    # Copy to clipboard and paste at cursor
                    p = Popen(['xsel', '-ib'], stdin=PIPE)
                    p.communicate(input=result["text"].encode())
                    Popen(['xdotool', 'type', result["text"]])
                    Popen(['xdotool', 'key', 'Return'])
except KeyboardInterrupt:
    print("\nTranscription stopped")
EOF
