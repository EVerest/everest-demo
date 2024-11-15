FROM ghcr.io/everest/everest-ci/build-kit-base:v1.4.2

ARG EVEREST_VERSION=2024.9.0
ENV EVEREST_VERSION=${EVEREST_VERSION}

# Cloning the repo now and copying files over
RUN git clone https://github.com/EVerest/everest-core.git \
        && cd everest-core \
        && git checkout ${EVEREST_VERSION} \
        && cd .. \
        && mkdir -p /ext/scripts \
        && cp -r everest-core/.ci/build-kit/scripts/* /ext/scripts/ \
        && mv everest-core /ext/source \
        && /entrypoint.sh run-script compile \
        && /entrypoint.sh run-script install

# Copy over the custom config *after* compilation and installation

COPY run-test.sh /ext/source/tests/run-test.sh

LABEL org.opencontainers.image.source=https://github.com/everest/everest-demo
