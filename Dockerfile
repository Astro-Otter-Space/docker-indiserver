# ==========
# Step 1 : INDI core
# =========
FROM ubuntu:24.04 AS build-core

ARG INDI_VERSION=""
LABEL stage=build-code

LABEL maintainer="Astro Otter <balistik.fonfon@gmail.com>" \
      description="INDI Server with drivers compiled" \
      version="1.0"

# Dependenciesi
RUN apt-get update && \
    apt-get install -y \
    git \
    cdbs \
    dkms \
    cmake \
    fxload \
    curl \
    jq \
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

# Si INDI_VERSION est vide -> récupérer le dernier tag depuis GitHub
RUN if [ -z "$INDI_VERSION" ]; then \
      INDI_VERSION=$(curl -s https://api.github.com/repos/indilib/indi/releases/latest | jq -r .tag_name); \
    fi && \
    echo "===> Building INDI version $INDI_VERSION" && \
    git clone --branch ${INDIVERSION} --depth 1  https://github.com/indilib/indi.git && \
    cd indi && \
    git pull origin --no-rebase && \
    mkdir -p /src/Projects/build/indi-core && cd /src/Projects/build/indi-core && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug ~/Projects/indi && \
    make -j4 && \
    make install


# ==========
# Step 2 : INDI libraries
# =========
FROM build-core AS build-drivers

ARG INDI_DRIVERS=""
WORKDIR /src/Projects

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
      git clone --branch ${INDIVERSION} --depth 1 https://github.com/indilib/indi-3rdparty.git && \
      cd indi-3rdparty && \
      git pull origin --no-rebase && \
      for drv in $INDI_DRIVERS; do \
        echo \"===> Building driver: $drv\" && \
        mkdir -p /src/Projects/build/{$drv} && cd /src/Projects/build/{$drv} && \
        cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug /src/${BUILDDIR}/indi-3rdparty/{$drv} && \
        make -j4 && \
        make install \
      done; \
    else \
      echo "===> No extra drivers requested"; \
    fi

# ==========
# Step 3 : Runtime
# =========
FROM ubuntu:24.04

ARG INDI_VERSION=""
ARG INDI_DRIVERS=""

LABEL maintainer="Astro Otter <balistik.fonfon@gmail.com>" \
      description="INDI Server with drivers compiled" \
      version="1.0"

RUN apt-get update && \
    apt-get install -y \
    libnova0 libcfitsio9 libusb-1.0-0 libjpeg8 libcurl4 libgsl27 libtiff5 && \
    rm -rf /var/lib/apt/lists/*

# Copier indi-core
COPY --from=build-core /usr/bin/indiserver /usr/bin/
COPY --from=build-core /usr/bin/indi_* /usr/bin/
COPY --from=build-core /usr/lib/*/indi/ /usr/lib/x86_64-linux-gnu/indi/
COPY --from=build-core /usr/share/indi/ /usr/share/indi/

# Copier drivers tiers si demandés
COPY --from=build-drivers /usr/bin/indi_* /usr/bin/
COPY --from=build-drivers /usr/lib/*/indi/ /usr/lib/x86_64-linux-gnu/indi/
COPY --from=build-drivers /usr/share/indi/ /usr/share/indi/

EXPOSE 7624

ENTRYPOINT ["indiserver"]
CMD ["-v"]
