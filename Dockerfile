# Stage 1: Builder environment
FROM ubuntu:22.04 AS builder

# Install build dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    git \
    make \
    libsdl2-dev \
    ffmpeg \
    wget \
    software-properties-common \
    g++ \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Install CUDA
RUN wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb \
    && dpkg -i cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb \
    && cp /var/cuda-repo-ubuntu2204-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/ \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends cuda-11-8 \
    && rm -rf /var/lib/apt/lists/* \
    && rm cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb

ENV CUDA_HOME=/usr/local/cuda-11.8 \
    PATH="/usr/local/cuda-11.8/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/cuda-11.8/lib64:${LD_LIBRARY_PATH}"

# Build whisper.cpp
WORKDIR /usr/local/src
RUN git clone https://github.com/ggerganov/whisper.cpp.git -b v1.7.4 --depth 1
WORKDIR /usr/local/src/whisper.cpp
RUN bash ./models/download-ggml-model.sh small.en && \
    cmake -B build \
        -DWHISPER_SDL2=ON \
        -DGGML_CUDA=1 \
        -DCUDAToolkit_ROOT=/usr/local/cuda-11.8 && \
    cmake --build build -j --config Release && \
    make -j$(nproc) 

# Stage 2: Runtime environment
FROM ubuntu:22.04

# Install ALL dependencies in one layer
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    libsdl2-2.0-0 \
    ffmpeg \
    pulseaudio \
    pulseaudio-utils \
    libasound2-plugins \
    alsa-utils \
    sox \
    make \
    lame \
    ydotool \
    libsox-fmt-mp3 \
    g++ \
    libasound2-dev \
    libx11-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy CUDA runtime
COPY --from=builder /usr/local/cuda-11.8/lib64 /usr/local/cuda-11.8/lib64/

# Copy whisper.cpp artifacts
COPY --from=builder /usr/local/src/whisper.cpp/build/ /usr/local/src/whisper.cpp/build/
COPY --from=builder /usr/local/src/whisper.cpp/models/ggml-small.en.bin /usr/local/src/whisper.cpp/models/

# Environment configuration
ENV CUDA_HOME=/usr/local/cuda-11.8 \
    PATH="/usr/local/cuda-11.8/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/cuda-11.8/lib64:${LD_LIBRARY_PATH}"

# Audio configuration
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

# Final setup
RUN useradd -m -G audio pulseuser
WORKDIR /root/type_ws/
CMD ["tail", "-f", "/dev/null"]
