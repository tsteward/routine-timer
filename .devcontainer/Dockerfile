# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/devcontainers/base:jammy

ARG USERNAME=vscode
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH=${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}

# Core dependencies and build tools for Flutter (web and Linux desktop)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils zip \
    libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK (stable channel)
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && mkdir -p /home/${USERNAME}/.pub-cache \
    && chown -R ${USERNAME}:${USERNAME} ${FLUTTER_HOME} /home/${USERNAME}/.pub-cache

# Avoid analytics noise from CI/containers
ENV FLUTTER_DISABLE_ANALYTICS=true
