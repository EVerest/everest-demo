FROM ghcr.io/everest/everest-ci/build-kit-base:v1.4.2

ARG EVEREST_VERSION=2024.9.0
ENV EVEREST_VERSION=${EVEREST_VERSION}

RUN echo "Copying compile-time patches before starting compile"

COPY demo-patches/ /tmp/demo-patches/
COPY demo-patch-scripts/ /tmp/demo-patch-scripts/

RUN echo "Installing patch and vim"
RUN apt-get -y -qq update
RUN apt-get install -y -qq patch
RUN apt-get install -y -qq vim

# Cloning the repo now and copying files over
RUN git clone https://github.com/EVerest/everest-core.git \
        && cd everest-core \
        && git checkout ${EVEREST_VERSION} \
        && cd .. \
        && mkdir -p /ext/scripts \
        && cp -r everest-core/.ci/build-kit/scripts/* /ext/scripts/ \
        && mv everest-core /ext/source \
        && bash /tmp/demo-patch-scripts/apply-compile-patches.sh \
        && /entrypoint.sh run-script compile \
        && /entrypoint.sh run-script install

# The previous approach works for code patches to the
# modules in everest-core, which are checked out as part
# of the build. However, it does not work for patches to the
# libraries that the modules use because the modules are
# downloaded as part of the build

# so we need to apply them post-build and then recompile and
# re-install. If there was a way to split the prep and the
# build (e.g. between the cmake and the ninja, we could apply
# it there. But this is what we have to work with :(

RUN bash /tmp/demo-patch-scripts/apply-library-patches.sh
RUN    /entrypoint.sh run-script compile \
    && /entrypoint.sh run-script install

# cleanup
RUN apt-get -y remove --purge build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/*

# Copy over the non-compiled patches *after* compilation and installation
RUN echo "Applying Post-Build patches..."
RUN bash /tmp/demo-patch-scripts/apply-runtime-patches.sh

# Setup python stuff for the more complex simulator
# and for testing if needed
RUN pip install --break-system-packages numpy==2.1.3
RUN pip install --break-system-packages control==0.10.1
RUN pip install --break-system-packages paho-mqtt==2.1.0

COPY run-test.sh /ext/source/tests/run-test.sh

LABEL org.opencontainers.image.source=https://github.com/everest/everest-demo
