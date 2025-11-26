FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    g++ \
    make \
    libsigc++-2.0-dev \
    libgsm1-dev \
    libpopt-dev \
    tcl8.6-dev \
    libgcrypt-dev \
    libspeex-dev \
    libasound2-dev \
    alsa-utils \
    libsigc++-2.0-0v5 \
    cmake \
    groff \
    rtl-sdr \
    libusb-1.0-0-dev \
    libusb-1.0-0 \
    unzip \
    git \
    rsync \
    python3 \
    build-essential \
    wget \
    curl \
    libtool \
    sudo \
    zlib1g-dev \
    libfftw3-3 \
    libasound2 \
    netcat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /workspace

COPY libpng-1.2.59.tar.xz .

RUN tar xf libpng-1.2.59.tar.xz \
    && cd libpng-1.2.59 \
    && ./autogen.sh \
    && ./configure --disable-dependency-tracking \
    && make \
    && make install

COPY .devcontainer/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb .
RUN dpkg -i libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb

USER vscode

