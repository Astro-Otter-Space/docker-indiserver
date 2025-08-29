# ----------------------------
# Stage 1 : Build INDI core
# ----------------------------
FROM ubuntu:24.04 AS build-core

ARG DEBIAN_FRONTEND=noninteractive
ARG INDI_VERSION=""

LABEL maintainer="Astro Otter <balistik.fonfon@gmail.com>" \
      description="INDI Server with drivers compiled" \
      version="1.0"

# Dépendances build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cdbs cmake curl dkms git fxload jq pkg-config \
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
    rm -rf /var/lib/apt/lists/*

WORKDIR /src/Projects

# If INDI_VERSION is empty -> get lat tag from github
RUN if [ -z "$INDI_VERSION" ]; then \
      INDI_VERSION=$(git ls-remote --tags https://github.com/indilib/indi.git | \
                     awk -F/ '{print $3}' | grep -E '^v?[0-9]+\.[0-9]+' | \
                     sort -Vr | head -n1); \
    fi && \
    git clone --branch "$INDI_VERSION" --depth=1 https://github.com/indilib/indi.git


# Compilation
RUN git pull origin --no-rebase && \
RUN mkdir -p /src/Projects/build/indi-core && cd /src/Projects/build/indi-core && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug ~/Projects/indi && \
    make -j$(nproc) && make install


# ----------------------------
# Stage 2 : Build extra drivers
# ----------------------------
FROM build-core AS build-drivers

ARG INDI_DRIVERS=""
WORKDIR /src/Projects

# Dépendances pour drivers tiers
RUN apt-get update && \
    apt-get install -y \
    libnova-dev libcfitsio-dev \ libusb-1.0-0-dev zlib1g-dev libgsl-dev build-essential cmake git \
    libjpeg-dev libcurl4-gnutls-dev libtiff-dev libfftw3-dev libftdi-dev libgps-dev libraw-dev libdc1394-dev \
    libgphoto2-dev libboost-dev libboost-regex-dev librtlsdr-dev liblimesuite-dev libftdi1-dev libavcodec-dev \
    libavdevice-dev libzmq3-dev libudev-dev \
    extra-cmake-modules \

# Only for Raspberry PI
RUN if echo "$INDI_DRIVERS" | grep -qw "indi_libcamera"; then \
      echo "===> Installing rpicamlib-dev for indi_libcamera" && \
      apt-get update && apt-get install -y libcamera-dev librpicam-app-dev && rm -rf /var/lib/apt/lists/*; \
    fi

RUN if [ -n "$INDI_DRIVERS" ]; then \
      echo "===> Building extra drivers: $INDI_DRIVERS" && \
      git clone --branch v${INDI_VERSION} --depth 1 https://github.com/indilib/indi-3rdparty.git && \
      cd indi-3rdparty && \
      git pull origin --no-rebase && \
      for drv in $INDI_DRIVERS; do \
        echo \"===> Building driver: $drv\" && \
        mkdir -p /src/Projects/build/{$drv} && cd /src/Projects/build/{$drv} && \
        cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug /src/${BUILDDIR}/indi-3rdparty/{$drv} && \
        make -j$(nproc) && make install \
      done; \
    else \
      echo "===> No extra drivers requested"; \
    fi


# ----------------------------
# Stage 3 : Runtime image
# ----------------------------
FROM ubuntu:24.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-setuptools python3-wheel \
    libnova0 libcfitsio9 libusb-1.0-0 libjpeg8 libcurl4 libgsl27 libtiff5 && \
    rm -rf /var/lib/apt/lists/*

# Copier indi-core
COPY --from=build-core /usr/local/bin/ /usr/local/bin/
COPY --from=build-core /usr/local/lib/ /usr/local/lib/
COPY --from=build-core /usr/local/share/indi/ /usr/local/share/indi/

COPY --from=build-drivers /usr/local/bin/ /usr/local/bin/
COPY --from=build-drivers /usr/local/lib/ /usr/local/lib/
COPY --from=build-drivers /usr/local/share/indi/ /usr/local/share/indi/

# Install indiwebmanager
RUN pip3 install --no-cache-dir indiweb

EXPOSE 7624
EXPOSE 8624

ENTRYPOINT ["indi-web", "--host", "0.0.0.0", "--port", "8624"]
