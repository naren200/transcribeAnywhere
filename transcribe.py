# transcribe.py
import queue
import sys
import os
import sounddevice as sd
import vosk 
import time
import json
from subprocess import Popen, PIPE

# Get environment variables
SAMPLE_RATE = int(os.environ.get('SAMPLE_RATE', 16000))
FRAME_SIZE = int(os.environ.get('FRAME_SIZE', 8000))

# Initialize Vosk with large model for better accuracy
model = vosk.Model("/app/model/model")
q = queue.Queue()

def callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    q.put(bytes(indata))

try:
    with sd.RawInputStream(samplerate=SAMPLE_RATE, 
                         blocksize=FRAME_SIZE,
                         dtype='int16', 
                         channels=1, 
                         callback=callback):
        
        rec = vosk.KaldiRecognizer(model, SAMPLE_RATE)
        
        while True:
            data = q.get()
            if rec.AcceptWaveform(data):
                result = json.loads(rec.Result())
                if result["text"]:
                    # Copy to clipboard
                    p = Popen(['xsel', '-ib'], stdin=PIPE)
                    p.communicate(input=result["text"].encode())
                    # Type text without pressing enter
                    Popen(['xdotool', 'type', result["text"]])


except Exception as e:
    print(f"Error: {e}")
    # Attempt to reconnect or restart the recognition
    time.sleep(1)
    os.execl(sys.executable, sys.executable, *sys.argv)

except KeyboardInterrupt:
    print("\nTranscription stopped")


