FROM ghcr.io/catarial/everest-ci/build-kit-base:v1.5.2

ARG EVEREST_VERSION=2025.3.0
ENV EVEREST_VERSION=${EVEREST_VERSION}

RUN echo "Copying compile-time patches before starting compile"

COPY . /tmp/

RUN echo "Installing patch and vim"
RUN bash /tmp/os-pkg-install.sh

# Cloning the repo now and copying files over
RUN echo "Clone and initial compile"
RUN bash /tmp/initial-install.sh
RUN /entrypoint.sh run-script compile \
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

RUN echo "Applying library patches"
RUN bash /tmp/demo-patch-scripts/apply-library-patches.sh
RUN /entrypoint.sh run-script compile \
   && /entrypoint.sh run-script install

# cleanup
RUN apt-get -y remove --purge build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/*

# Copy over the non-compiled patches *after* compilation and installation
RUN echo "Applying Post-Build patches..."
RUN bash /tmp/demo-patch-scripts/apply-runtime-patches.sh

COPY run-test.sh /ext/source/tests/run-test.sh

LABEL org.opencontainers.image.source=https://github.com/everest/everest-demo
