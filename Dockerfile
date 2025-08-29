# ==========
# BUILD
# =========
FROM ubuntu:24.04 AS build

ARG INDI_VERSION=""
LABEL stage=build

LABEL maintainer="Astro Otter <balsitik.fonfon@gmail.com>" \
      description="INDI Server compiled from indi-core" \
      version="1.0"

# Dependencies
RUN apt-get update && \
    apt-get install -y \


WORKDIR /src

# Si INDI_VERSION est vide -> récupérer le dernier tag depuis GitHub
RUN if [ -z "$INDI_VERSION" ]; then \
      INDI_VERSION=$(curl -s https://api.github.com/repos/indilib/indi/releases/latest | jq -r .tag_name); \
    fi && \
    echo "===> Building INDI version $INDI_VERSION" && \
    git clone https://github.com/indilib/indi.git && \
    cd indi && \
    git checkout $INDI_VERSION && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j$(nproc) && \
    make install


