FROM ubuntu:18.04 AS builder
MAINTAINER Adam Harrison-Fuller <adam@adamhf.io>

# Define Mumble version
ARG MUMBLE_VERSION=1.3.0

# Create Mumble directories
RUN mkdir -pv /build/mumble

WORKDIR /build/mumble

RUN apt-get update && apt-get install -y build-essential pkg-config qt5-default qttools5-dev-tools libqt5svg5-dev \
    libboost-dev libasound2-dev libssl-dev \
    libspeechd-dev libzeroc-ice-dev libpulse-dev \
    libcap-dev libprotobuf-dev protobuf-compiler \
    libogg-dev libavahi-compat-libdnssd-dev libsndfile1-dev \
    libg15daemon-client-dev libxi-dev git

RUN git clone https://github.com/mumble-voip/mumble.git mumble &&\
    cd mumble &&\ 
    git checkout ${MUMBLE_VERSION} &&\
    git submodule init &&\
    git submodule update

RUN cd mumble && \
    qmake -recursive main.pro CONFIG+=no-client && \
    make -j4


FROM ubuntu:18.04
# Create Mumble directories
RUN mkdir -pv /opt/mumble /etc/mumble

# Create non-root user
RUN useradd -ms /sbin/nologin mumble
# Copy config file
COPY files/config.ini /etc/mumble/config.ini
# Copy SuperUser password update script
COPY files/supw /usr/local/bin/supw
RUN chmod +x /usr/local/bin/supw
COPY --from=builder /build/mumble/mumble/release/murmurd /opt/mumble/murmurd
# Expose ports
EXPOSE 64738 64738/udp

# Set running user
USER mumble

# Set volumes
VOLUME /etc/mumble

# Default command
CMD ["/opt/mumble/murmurd", "-fg", "-ini", "/etc/mumble/config.ini"]