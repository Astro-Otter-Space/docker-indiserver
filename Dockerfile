# ----------------------------
# Stage 1 : Build INDI core
# ----------------------------
FROM debian:bookworm-slim AS build-core
ARG DEBIAN_FRONTEND=noninteractive
ARG INDI_VERSION=""
ARG INDI_DRIVERS=""
LABEL maintainer="Astro Otter <balistik.fonfon@gmail.com>" \
      description="INDI Server with drivers compiled" \
      version="1.0"

# Dépendances build
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates build-essential cdbs cmake curl dkms git fxload jq pkg-config \
    libev-dev \
    libgps-dev \
    libgsl-dev \
    libraw-dev \
    libusb-dev \
    zlib1g-dev \
    libftdi-dev \
    libjpeg-dev \
    libkrb5-dev \
    libnova-dev \
    libtiff-dev \
    libfftw3-dev \
    librtlsdr-dev \
    libcfitsio-dev \
    libgphoto2-dev \
    build-essential \
    libusb-1.0-0-dev \
    libdc1394-dev \
    libboost-regex-dev \
    libcurl4-gnutls-dev \
    libtheora-dev && \
    update-ca-certificates

# Create user
RUN useradd -ms /bin/bash astro && \
    usermod -aG sudo astro && \
    echo 'astro ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Run as user
RUN mkdir -p /home/astro/Projects

# Clone INDI core
RUN set -e; \
    if [ -z "$INDI_VERSION" ]; then \
      INDI_VERSION=$(git ls-remote --tags https://github.com/indilib/indi.git \
        | awk -F/ '{print $3}' \
        | grep -E '^v?[0-9]+\.[0-9]+' \
        | sort -Vr \
        | head -n1); \
    fi && \
    echo "Using INDI_VERSION=$INDI_VERSION"; \
    git clone --branch "$INDI_VERSION" --depth=1 https://github.com/indilib/indi.git /home/astro/Projects/indi

# Compilation
RUN mkdir -p /home/astro/Projects/build/indi-core && cd /home/astro/Projects/build/indi-core && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug /home/astro/Projects/indi && \
    make -j$(nproc) && make install

WORKDIR /home/astro
# ----------------------------
# Stage 2 : Build extra drivers
# ----------------------------
FROM build-core AS build-drivers
ARG DEBIAN_FRONTEND=noninteractive
ARG INDI_VERSION=""
ARG INDI_DRIVERS=""
USER root
WORKDIR /home/astro/Projects

# Dépendances pour drivers tiers
RUN apt-get update && \
    apt-get install -y \
    libnova-dev libcfitsio-dev libusb-1.0-0-dev zlib1g-dev libgsl-dev build-essential \
    libjpeg-dev libcurl4-gnutls-dev libtiff-dev libfftw3-dev libftdi-dev libgps-dev libraw-dev libdc1394-dev \
    libgphoto2-dev libboost-dev libboost-regex-dev librtlsdr-dev liblimesuite-dev libftdi1-dev libavcodec-dev \
    libavdevice-dev libzmq3-dev libudev-dev \
    extra-cmake-modules && \
    rm -rf /var/lib/apt/lists/*

# Only for Raspberry PI
RUN if echo "$INDI_DRIVERS" | grep -qw "indi_libcamera"; then \
      echo "===> Installing rpicamlib-dev for indi_libcamera" && \
      apt-get update && apt-get install -y libcamera-dev librpicam-app-dev && rm -rf /var/lib/apt/lists/*; \
    fi

WORKDIR /home/astro/Projects

# Build extra drivers
RUN if [ -n "$INDI_DRIVERS" ]; then \
      echo "===> Building extra drivers: $INDI_DRIVERS" && \
      echo "Using INDI_VERSION=$INDI_VERSION for 3rd parties"; \
      git clone --branch "$INDI_VERSION" --depth=1 https://github.com/indilib/indi-3rdparty.git /home/astro/Projects/indi-3rdparty && \
      for drv in $INDI_DRIVERS; do \
        echo "===> Building driver: $drv" && \
        if [ -d "/home/astro/Projects/indi-3rdparty/$drv" ]; then \
          mkdir -p /home/astro/Projects/build/"$drv" && cd /home/astro/Projects/build/"$drv" && \
          cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug /home/astro/Projects/indi-3rdparty/"$drv" && \
          make -j$(nproc) && make install; \
        else \
          echo "WARNING: Driver directory '$drv' not found in indi-3rdparty repository" && \
          echo "Available drivers in repository:" && \
          ls -1 /home/astro/Projects/indi-3rdparty/ | grep "^indi-" || true; \
        fi; \
      done; \
    else \
      echo "===> No extra drivers requested"; \
    fi

# ----------------------------
# Stage 3 : Runtime image
# ----------------------------
FROM debian:bookworm-slim AS runtime
ARG DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip python3-setuptools python3-wheel && \
    rm -rf /var/lib/apt/lists/*

## Copy from stages
COPY --from=build-core /usr/bin/ /usr/bin/
COPY --from=build-core /usr/lib/ /usr/lib/
COPY --from=build-core /usr/share/indi/ /usr/share/indi/
COPY --from=build-drivers /usr/bin/ /usr/bin/
COPY --from=build-drivers /usr/lib/ /usr/lib/
COPY --from=build-drivers /usr/share/indi/ /usr/share/indi/

# Install indiwebmanager
RUN pip3 install --no-cache-dir --break-system-packages indiweb

EXPOSE 8624
ENTRYPOINT ["indi-web"]
CMD ["--host", "0.0.0.0", "--port", "8624"]
