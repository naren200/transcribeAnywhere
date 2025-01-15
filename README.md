# transcribeAnywhere

A real-time speech-to-text transcription service using Vosk speech recognition, packaged in a Docker container. This application transcribes speech and automatically types the text anywhere you place your cursor, making it useful for dictation and accessibility purposes, especially communicating with locally-run and web-service LLMs.


## Features

- Real-time speech-to-text transcription
- Automatic text typing without manual intervention
- Uses the large Vosk model (vosk-model-en-us-0.22-lgraph) for better accuracy
- Docker containerized for easy deployment
- ALSA audio integration
- Clipboard integration

## Prerequisites

- Docker installed on your system
- Linux operating system with ALSA and PulseAudio
- Working microphone
- X11 display server running

## Quick Start

### Option 1: Using Pre-built Image
Size of the image: 882.94 MB
```bash
docker pull naren200/transcribeanywhere:v1
```

### Option 2: Building from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/transcribeAnywhere.git
cd transcribeAnywhere
```

2. Build the Docker image:
```bash
docker build -t naren200/transcribeanywhere:v1 .
```

### Running the Container

```bash
docker run -it \
    --device /dev/snd:/dev/snd \
    -e DISPLAY=$DISPLAY \
    -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
    -v ~/.config/pulse/cookie:/root/.config/pulse/cookie \
    --group-add $(getent group audio | cut -d: -f3) \
    naren200/transcribeanywhere:v1
```

## Project Structure

```
transcribeAnywhere/
├── transcribe.py    # Main Python script for speech recognition
├── transcribe.sh    # Shell script wrapper
├── Dockerfile       # Docker configuration
└── README.md       # Documentation
```

## Configuration

### Audio Settings
- Sample Rate: 16000 Hz
- Frame Size: 8000
- Buffer Size: 16000
- Period Size: 8000

These can be adjusted in the ALSA configuration within the Dockerfile.

## Dependencies

### System Dependencies
- ffmpeg
- sox
- ALSA utilities
- PulseAudio
- X11
- xdotool
- xsel

### Python Dependencies
- vosk
- sounddevice
- numpy
- scipy
- noisereduce

## Troubleshooting

1. Audio Device Issues
   - Check if your microphone is properly connected
   - Verify ALSA/PulseAudio configuration
   - Check audio group permissions

2. Display Issues
   - Ensure X11 is running
   - Verify DISPLAY environment variable

3. Permission Issues
   - Make sure user has access to audio group
   - Check device permissions

## Known Limitations

- Currently supports English language only
- Requires X11 display server
- May experience latency with larger speech segments
- Audio device sample rate must match configuration

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Vosk Speech Recognition Toolkit](https://alphacephei.com/vosk/)
- [Python sounddevice library](https://python-sounddevice.readthedocs.io/)
- Docker community