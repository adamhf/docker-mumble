FROM ubuntu:18.04 AS builder
MAINTAINER Adam Harrison-Fuller <adam@adamhf.io>

ENV DEBIAN_FRONTEND=noninteractive

# Define Mumble version
ARG MUMBLE_VERSION=1.3.3

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    qt5-default \
    qttools5-dev-tools \
    libqt5svg5-dev \
    libboost-dev \
    libasound2-dev \
    libssl-dev \
    libspeechd-dev \
    libzeroc-ice-dev \
    libpulse-dev \
    libcap-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libogg-dev \
    libavahi-compat-libdnssd-dev \
    libsndfile1-dev \
    libg15daemon-client-dev \
    libxi-dev git

# Create Mumble directories
RUN mkdir -pv /build/mumble

#Set a base work dir
WORKDIR /build/

# Clone the repo, checkout the version tag and build.
RUN git clone https://github.com/mumble-voip/mumble.git mumble && \
    cd mumble && \ 
    git checkout ${MUMBLE_VERSION} && \
    git submodule init && \
    git submodule update && \
    qmake -recursive main.pro CONFIG+=no-client CONFIG+=no-ice && \
    make -j4


FROM ubuntu:18.04

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-armhf /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

ENV DEBIAN_FRONTEND=noninteractive
# Create non-root user
RUN useradd -ms /sbin/nologin mumble
# Creat and set ownership of data data and config directories.
RUN mkdir -pv /opt/mumble /config /data && chown mumble:mumble /data /config
# Install murmurd's run time requirements.
RUN apt-get update && apt-get -y install \
    libcap2 \
    libssl1.1 \
    libprotobuf10 \
    libavahi-compat-libdnssd1 \
    libqt5network5 \
    libqt5sql5 \
    libqt5xml5 \
    && rm -rf /var/lib/apt/lists/*
# Copy SuperUser password update script
COPY files/supw /usr/local/bin/supw
RUN chmod +x /usr/local/bin/supw
COPY --from=builder /build/mumble/release/murmurd /opt/mumble/murmurd
COPY --from=builder /build/mumble/scripts/murmur.ini /config/murmur.ini
# Expose ports
EXPOSE 64738 64738/udp

# Set running user
USER mumble

# Set volumes
VOLUME /data
VOLUME /config

# Default command
CMD ["/opt/mumble/murmurd", "-fg", "-ini", "/config/murmur.ini"]

