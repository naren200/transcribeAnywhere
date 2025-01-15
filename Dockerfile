FROM python:3.9-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    ffmpeg \
    unzip \
    sox \
    git \
    make \
    g++ \
    xsel \
    wget \
    curl \
    cmake \
    python3-pip \
    libportaudio2 \
    portaudio19-dev \
    libasound2 \
    libasound2-plugins \
    libsndfile1 \
    python3-pyaudio \
    pulseaudio \
    alsa-utils \
    xdotool 

# Add ALSA config with explicit sample rateh
RUN echo 'pcm.!default { \n\
        type plug \n\
        slave { \n\
            pcm "hw:0,0" \n\
            rate 44100 \n\
        } \n\
    }\n\
    defaults.pcm.rate_converter "speexrate_medium"\n\
    ' > /etc/asound.conf

# Add audio group
RUN usermod -a -G audio root

# Install Python dependencies
RUN pip3 install sounddevice vosk numpy

# Create working directory
WORKDIR /app

# Download Vosk model
RUN mkdir model && \
    cd model && \
    wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip && \
    unzip vosk-model-small-en-us-0.15.zip && \
    mv vosk-model-small-en-us-0.15 model

# Install Python dependencies
RUN pip3 install vosk sounddevice numpy

COPY ./transcribe.sh /app/
RUN chmod +x /app/transcribe.sh

ENTRYPOINT ["/app/transcribe.sh"]
