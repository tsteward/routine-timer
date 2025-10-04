# Use Ubuntu as base image
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment variables for Flutter
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"
ENV PUB_CACHE=/root/.pub-cache

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# Pre-download Flutter dependencies
RUN flutter doctor -v
RUN flutter precache

# Accept Android licenses (if you plan to build for Android)
RUN yes | flutter doctor --android-licenses || true

# Set working directory
WORKDIR /workspace

# Run flutter doctor to verify installation
RUN flutter doctor

# Default command
CMD ["/bin/bash"]
