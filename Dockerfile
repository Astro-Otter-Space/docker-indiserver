# ----------------------------
# Stage 1 : Build INDI core & drivers
# ----------------------------
FROM debian:bookworm-slim AS build
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
    libusb-1.0-0-dev \
    libdc1394-dev \
    libboost-regex-dev \
    libcurl4-gnutls-dev \
    libtheora-dev \
    # Dépendances supplémentaires pour drivers tiers \
    libboost-dev \
    liblimesuite-dev \
    libftdi1-dev \
    libavcodec-dev \
    libavdevice-dev \
    libzmq3-dev \
    libudev-dev \
    extra-cmake-modules && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -ms /bin/bash astro && \
    usermod -aG sudo astro && \
    echo 'astro ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Run as user
RUN mkdir -p /home/astro/Projects

# Clone and build INDI core
RUN set -e; \
    if [ -z "$INDI_VERSION" ]; then \
      INDI_VERSION=$(git ls-remote --tags https://github.com/indilib/indi.git \
        | awk -F/ '{print $3}' \
        | grep -E '^v?[0-9]+\.[0-9]+' \
        | sort -Vr \
        | head -n1); \
    fi && \
    echo "===> Using INDI version $INDI_VERSION" && \
    git clone --branch "$INDI_VERSION" --depth=1 https://github.com/indilib/indi.git /home/astro/Projects/indi && \
    mkdir -p /home/astro/Projects/build/indi-core && cd /home/astro/Projects/build/indi-core && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug /home/astro/Projects/indi && \
    make -j$(nproc) && make install && \
    # Build extra drivers with same INDI_VERSION \
    if [ -n "$INDI_DRIVERS" ]; then \
      echo "===> Building extra drivers: $INDI_DRIVERS" && \
      echo "==> Using INDI version $INDI_VERSION for 3rd parties" && \
      git clone --branch "$INDI_VERSION" --depth=1 https://github.com/indilib/indi-3rdparty.git /home/astro/Projects/indi-3rdparty && \
      mkdir -p /home/astro/Projects/build/indi-3rdparty-libs && cd /home/astro/Projects/build/indi-3rdparty-libs && \
      cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DBUILD_LIBS=1 /home/astro/Projects/indi-3rdparty && \
      make -j$(nproc) && make install && \
      echo "$INDI_DRIVERS" | tr ' ' '\n' | while IFS= read -r drv; do \
        if [ -n "$drv" ]; then \
          echo "===> Building driver: $drv" && \
          if [ -d "/home/astro/Projects/indi-3rdparty/$drv" ]; then \
            mkdir -p /home/astro/Projects/build/"$drv" && \
            cd /home/astro/Projects/build/"$drv" && \
            cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug /home/astro/Projects/indi-3rdparty/"$drv" && \
            make -j$(nproc) && make install; \
          else \
            echo "WARNING: Driver directory '$drv' not found in indi-3rdparty repository" && \
            echo "Available drivers in repository:" && \
            ls -1 /home/astro/Projects/indi-3rdparty/ | grep "^indi-" || true; \
          fi; \
        fi; \
      done; \
    else \
      echo "===> No extra drivers requested"; \
    fi

WORKDIR /home/astro/Projects

# ----------------------------
# Stage 2 : Runtime image
# ----------------------------
FROM debian:bookworm-slim  AS runtime
ARG DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip python3-setuptools python3-wheel && \
    rm -rf /var/lib/apt/lists/*

## Copy from stages
COPY --from=build /usr/bin/indi* /usr/bin/
COPY --from=build /usr/lib/*indi* /usr/lib/
COPY --from=build /usr/share/indi/*indi* /usr/share/indi/

# Install indiwebmanager
RUN pip3 install --no-cache-dir --break-system-packages indiweb

EXPOSE 8624
ENTRYPOINT ["indi-web"]
CMD ["--host", "0.0.0.0", "--port", "8624"]