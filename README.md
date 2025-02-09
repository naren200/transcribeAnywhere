# TranscribeAnywhere

## Overview

TranscribeAnywhere is an efficient transcription tool dedicated to Linux OS that enables seamless voice-to-text conversion using Whisper.cpp. The project is designed for users who want to transcribe their thoughts hands-free with minimal GPU memory usage. It requires a Linux-based operating system to function properly.

### Feature

- Supports **Whisper.cpp** for efficient transcription
- **Low GPU memory usage** (1000 MiB)
- **Docker-based deployment** for easy setup
- **Multi-platform compatibility**
- **Hotkey support** for quick start/stop
- **Integration with AI platforms** (Perplexity, ChatGPT, Across Linux)
- **Developer mode** for debugging and modifications
- Real-time transcription with minimal latency

## Installation

### Prerequisites

Ensure you have the following installed on your system:

- **Docker**
- **Devil's Pie** (for window management)
- **XTerm** (for terminal-based interactions)
- **PulseAudio** (for audio processing)

### Install Required Dependencies
1. **Install Docker on Ubuntu 22.04**  
   Follow the guide to install Docker:  
   [How to Install and Use Docker on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04)

2. **Perform Post-Installation Steps for Docker**  
   Ensure you complete the post-installation steps as outlined here:  
   [Post-Installation Steps for Docker on Linux](https://docs.docker.com/engine/install/linux-postinstall/)

3. **Install Docker Compose on Ubuntu 22.04**  
   Set up Docker Compose using the instructions here:  
   [How to Install and Use Docker Compose on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-22-04)
4. **Installation of required dependancies**
```bash
sudo apt update
sudo apt install devilspie xterm
```

### Copy Configuration Files

```bash
mkdir ~/.devilspie/
sudo cp transcribe.ds ~/.devilspie/
```

## Setting Up TranscribeAnywhere

### Option 1: Pull Prebuilt Docker Image

```bash
docker pull naren200/type_node:v1
```

### Option 2: Build from Source

```bash
git clone https://github.com/naren200/transcribeAnywhere.git
cd transcribeAnywhere
docker build -t naren200/type_node:v1 .
```

## Running Transcription

To start the transcription mode, run:

```bash
cd transcribeAnywhere
./start_docker.sh
```

To stop transcription mode:

```bash
cd transcribeAnywhere
./stop_docker.sh
```

## Hotkey Assignments (Linux)

For convenience, assign keyboard shortcuts. Use the following command to get the exact script directory and set it as SCRIPT_DIR:

```bash
SCRIPT_DIR=$(pwd)
```
 

```bash
$SCRIPT_DIR/start_transcribe.sh  # Ctrl+Alt+G
$SCRIPT_DIR/stop_transcribe.sh # Ctrl+Alt+H
```

## Customization

### Change the Whisper Model
Change the Whisper Model

Modify Dockerfile to specify a different model size by changing small.en to medium.en in line 34:
```bash
RUN bash ./models/download-ggml-model.sh medium.en
```
After making this change, rebuild the Docker image:
```bash
docker build -t naren200/type_node:v1 .
```

Modify `MODEL` under **start_docker.sh** to specify a different model

```bash
export MODEL="ggml-medium.en.bin"
```

### Changing Audio Capture Device

To list available audio devices:

```bash
./start_docker.sh --capture=1
```

By default, the capture device is set to **2**. Change it if needed:

```bash
./start_docker.sh --capture=2
```

## Developer Mode

To enable developer mode for debugging and manual testing:

```bash
./start_docker.sh --developer=true
```

This mode allows real-time modifications to **whisper\_handler.cpp**.

## Troubleshooting
### Capture Device Issues

If the capture mode does not work, you can list the available devices inside the Docker image and specify the correct capture device manually. To list all available capture devices, run:
```bash
./start_docker.sh --capture=1
```
Example output, choose the capture device which best suits based on your system:
```bash
Using capture device: 1
init: found 4 capture devices:
init:    - Capture device #0: 'sof-hda-dsp, '
init:    - Capture device #1: 'sof-hda-dsp,  (2)'
init:    - Capture device #2: 'sof-hda-dsp,  (3)'
init:    - Capture device #3: 'sof-hda-dsp,  (4)'
init: attempt to open capture device 1 : 'sof-hda-dsp,  (2)' ...
init: couldn't open an audio device for capture: ALSA: Couldn't open audio device: Invalid argument!
main: audio.init() failed!
```
If an error occurs, try selecting a different device and updating the default value in **start_transcript.sh**.

### PulseAudio Issues

If the capture mode does not work, restart PulseAudio:

```bash
pulseaudio -k  # Kill existing PulseAudio
pulseaudio --start  # Start PulseAudio
```

### Force Stop Transcription

If the model does not stop properly:

- Use the hotkey **Ctrl+Alt+H** to stop Docker.
- Or, force shutdown using **Ctrl+C** (twice if needed).

### Dockerfile Options

- **Dockerfile\_large**: Uses a **7GB** model for enhanced accuracy.
- Modify **line 34** in **Dockerfile** to change the model name.



## System Requirements

- GPU Memory: ~1000 MiB for whisper.cpp model
- Online models require 1500-4500 MiB through OpenAI Whisper Python library
- PulseAudio for audio capture

## Credits

This project is powered by:

- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- MIT License
- Inspired by [voice_typing](https://github.com/themanyone/voice_typing)

## License

This project follows the **MIT License**, ensuring free usage and modifications.
