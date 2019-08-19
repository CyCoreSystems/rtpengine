FROM debian:stretch AS builder

ENV RTPENGINE_VER=mr7.4.1.5
ENV BCG729_VER=1.0.4

RUN apt-get update
RUN apt-get install -y build-essential curl dpkg-dev devscripts equivs git pkg-config wget

# Install bcg729 library for building rtpengine with G.729 transcoding support
RUN curl -L -o /tmp/bcg729_${BCG729_VER}.orig.tar.gz https://codeload.github.com/BelledonneCommunications/bcg729/tar.gz/${BCG729_VER}
RUN tar xf /tmp/bcg729_${BCG729_VER}.orig.tar.gz -C /tmp
WORKDIR /tmp/bcg729-${BCG729_VER}
RUN git clone https://github.com/ossobv/bcg729-deb.git debian
RUN dpkg-buildpackage -us -uc -sa
WORKDIR /tmp
RUN dpkg -i $(find . -maxdepth 1 -name 'libbcg729-0_*.deb' -or -name 'libbcg729-dev*.deb')

# Or disable G.729 transcoding support
#ENV DEB_BUILD_PROFILES="pkg.ngcp-rtpengine.nobcg729"

# Pull down RTPEngine source
RUN curl -L -o /tmp/src.tar.gz https://github.com/sipwise/rtpengine/archive/${RTPENGINE_VER}.tar.gz
RUN tar xf /tmp/src.tar.gz -C /tmp
WORKDIR /tmp/rtpengine-${RTPENGINE_VER}

# Install other rtpengine dependencies
RUN mk-build-deps -B debian/control
RUN apt install -y ./$(ls ngcp-rtpengine-build-deps-*.deb)
RUN dpkg-buildpackage

# Build final image
FROM debian:stretch

COPY --from=builder /tmp/*.deb /tmp/

RUN apt-get update
RUN apt-get install -y libavcodec-extra

WORKDIR /tmp
RUN apt install -y $(ls /tmp/libbcg729-0_*.deb)
RUN apt install -y $(ls /tmp/ngcp-rtpengine-recording-daemon_*.deb)
RUN apt install -y $(ls /tmp/ngcp-rtpengine-utils_*.deb)
RUN apt install -y $(ls /tmp/ngcp-rtpengine-daemon_*.deb)
RUN apt install -y $(ls /tmp/ngcp-rtpengine-iptables_*.deb)
RUN apt install -y $(ls /tmp/ngcp-rtpengine-kernel-dkms_*.deb)

ADD entrypoint.sh /entrypoint.sh
