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
            rate 16000 \n\
            buffer_size 16000 \n\
            period_size 8000 \n\
        } \n\
    }\n\
    defaults.pcm.rate_converter "speexrate_best"\n\
    ' > /etc/asound.conf

# Add audio group
RUN usermod -a -G audio root

# Install Python dependencies
RUN pip3 install vosk sounddevice numpy noisereduce scipy

# Create working directory
WORKDIR /app

# Download Vosk model
RUN mkdir model && \
    cd model && \
    # wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip && \
    # unzip vosk-model-small-en-us-0.15.zip && \
    # mv vosk-model-small-en-us-0.15 model
    wget https://alphacephei.com/vosk/models/vosk-model-en-us-0.22-lgraph.zip && \
    unzip vosk-model-en-us-0.22-lgraph.zip && \
    mv vosk-model-en-us-0.22-lgraph model

# Install Python dependencies
RUN pip3 install vosk sounddevice numpy

COPY ./transcribe.sh /app/
COPY ./transcribe.py /app/
RUN chmod +x transcribe.sh transcribe.py


ENTRYPOINT ["/app/transcribe.sh"]
