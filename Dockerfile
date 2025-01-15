FROM python:3.9-slim

# Add to your Dockerfile
ENV NO_AT_BRIDGE=1
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    ffmpeg \
    sox \
    git \
    make \
    g++ \
    xsel \
    wget \
    curl \
    cmake \
    libglib2.0-dev \
    libtool \
    autoconf \
    automake \
    intltool \
    libgtk-3-dev \
    build-essential \
    xdotool \
    yad

# For X11 support
RUN apt-get install -y \
    x11-utils \
    x11-xserver-utils \
    xauth \
    xclip \
    pulseaudio \
    alsa-utils \
    libasound2 \
    libasound2-plugins


# Clone and build whisper.cpp
WORKDIR /app
RUN git clone https://github.com/ggerganov/whisper.cpp && \
    cd whisper.cpp && \
    cmake -B build && \
    cmake --build build --config Release


# Download model
RUN cd /app/whisper.cpp && \
    bash ./models/download-ggml-model.sh base.en

COPY ./transcribe.sh /app/
RUN chmod +x /app/transcribe.sh

ENTRYPOINT ["/app/transcribe.sh"]
