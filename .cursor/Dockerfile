# Use Ubuntu as base image
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment variables for Flutter
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"
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

# Add Flutter to PATH in .bashrc for interactive shells
RUN echo 'export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"' >> /root/.bashrc

# Pre-download Flutter dependencies
RUN flutter doctor -v
RUN flutter precache
RUN flutter config --no-analytics

# Accept Android licenses (if you plan to build for Android)
RUN yes | flutter doctor --android-licenses || true

# Create a symbolic link to make flutter globally accessible
RUN ln -s $FLUTTER_HOME/bin/flutter /usr/local/bin/flutter
RUN ln -s $FLUTTER_HOME/bin/dart /usr/local/bin/dart

# Set working directory
WORKDIR /workspace

# Verify installation
RUN flutter --version && dart --version

# Default command
CMD ["/bin/bash"]
