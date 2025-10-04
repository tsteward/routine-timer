# syntax=docker/dockerfile:1

# Use Ubuntu 22.04 LTS as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}
ENV FLUTTER_DISABLE_ANALYTICS=true

# Create a non-root user for development
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Basic utilities
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    wget \
    sudo \
    # Build tools for Flutter
    clang \
    cmake \
    ninja-build \
    pkg-config \
    # Linux desktop dependencies
    libglu1-mesa \
    libgtk-3-dev \
    liblzma-dev \
    # Android development dependencies
    openjdk-11-jdk \
    # Additional useful tools
    vim \
    nano \
    htop \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Create user and group
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install Flutter SDK as root and set proper ownership
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && git config --global --add safe.directory ${FLUTTER_HOME}

# Run Flutter doctor as root to download artifacts
RUN ${FLUTTER_HOME}/bin/flutter doctor -v \
    && ${FLUTTER_HOME}/bin/flutter config --no-analytics \
    && ${FLUTTER_HOME}/bin/flutter precache --linux --web

# Make Flutter writable for all users (needed for .dart_tool directories)
RUN chmod -R a+rw ${FLUTTER_HOME}

# Pre-accept Android licenses and install Android SDK
RUN mkdir -p /opt/android-sdk \
    && cd /opt/android-sdk \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip -q commandlinetools-linux-9477386_latest.zip \
    && rm commandlinetools-linux-9477386_latest.zip \
    && mkdir -p cmdline-tools/latest \
    && mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true \
    && rm -rf cmdline-tools/tools

# Set Android environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Install Android SDK components
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "sources;android-34"

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Configure git safe directory for the user
RUN git config --global --add safe.directory /opt/flutter

# Create pub cache directory
RUN mkdir -p /home/$USERNAME/.pub-cache

# Set user-specific environment variables
ENV PUB_CACHE=/home/$USERNAME/.pub-cache

# Set user-specific environment variables in profile
RUN echo 'export FLUTTER_HOME=/opt/flutter' >> ~/.bashrc \
    && echo 'export PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH' >> ~/.bashrc \
    && echo 'export FLUTTER_DISABLE_ANALYTICS=true' >> ~/.bashrc \
    && echo 'export PUB_CACHE=$HOME/.pub-cache' >> ~/.bashrc \
    && echo 'export ANDROID_HOME=/opt/android-sdk' >> ~/.bashrc \
    && echo 'export ANDROID_SDK_ROOT=/opt/android-sdk' >> ~/.bashrc \
    && echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc

# Also set in .profile for non-interactive shells
RUN echo 'export FLUTTER_HOME=/opt/flutter' >> ~/.profile \
    && echo 'export PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH' >> ~/.profile \
    && echo 'export FLUTTER_DISABLE_ANALYTICS=true' >> ~/.profile \
    && echo 'export PUB_CACHE=$HOME/.pub-cache' >> ~/.profile \
    && echo 'export ANDROID_HOME=/opt/android-sdk' >> ~/.profile \
    && echo 'export ANDROID_SDK_ROOT=/opt/android-sdk' >> ~/.profile \
    && echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.profile

# Create workspace directory
RUN mkdir -p /home/$USERNAME/workspace

# Set working directory
WORKDIR /home/$USERNAME/workspace

# Expose common Flutter development ports
EXPOSE 3000 8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090

# Default command
CMD ["/bin/bash"]