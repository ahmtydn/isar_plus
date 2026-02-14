FROM ubuntu:22.04

LABEL maintainer="Isar Plus Team"

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    build-essential \
    libssl-dev \
    pkg-config \
    libz-dev \
    lcov \
    wget \
    gnupg \
    llvm \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Chromium for web tests (Chromium is available for both amd64 and arm64)
# On Ubuntu 22.04, we use a PPA to get a real .deb instead of a snap
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:xtradeb/apps -y \
    && apt-get update && apt-get install -y chromium \
    && rm -rf /var/lib/apt/lists/*

# Set environment variable for Flutter to find Chromium
ENV CHROME_EXECUTABLE=/usr/bin/chromium

# Install Node.js for serving WASM
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${PATH}:${FLUTTER_HOME}/bin"
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME} \
    && flutter doctor

# Install Rust nightly
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly \
    && rustup component add rustfmt clippy \
    && cargo install cargo-tarpaulin \
    && cargo install wasm-bindgen-cli --version 0.2.108

# Set working directory
WORKDIR /app

# The entrypoint will be the coverage script
# CMD ["/bin/bash"]
