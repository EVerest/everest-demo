FROM --platform=linux/x86_64 ghcr.io/everest/build-kit-alpine:latest

ARG EVEREST_VERSION=2023.10.0
ENV EVEREST_VERSION=${EVEREST_VERSION}

COPY install.sh ./

# Cloning the repo now and copying files over
RUN git clone https://github.com/EVerest/everest-core.git \
        && cd everest-core \
        && git checkout ${EVEREST_VERSION} \
        && cd .. \
        && mkdir -p /ext/scripts \
        && mv install.sh /ext/scripts/install.sh \
        && mv everest-core /ext/source \
        && cp /ext/source/.ci/build-kit/compile.sh /ext/scripts \
        && /entrypoint.sh run-script compile \
        # Don't run the test-and-install script since it deletes the build directory!
        && /entrypoint.sh run-script install

# Copy over the custom config *after* the compile
COPY config-docker.json ./dist/share/everest/modules/OCPP/config-docker.json

LABEL org.opencontainers.image.source=https://github.com/everest/everest-demo
