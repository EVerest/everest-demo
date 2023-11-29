FROM ghcr.io/everest/build-kit-alpine:latest

RUN echo "Cloning the repo now and copying files over"
RUN sh -c "git clone https://github.com/EVerest/everest-core.git &&\
             mkdir -p /ext &&\
             mkdir -p /ext/scripts &&\
             mv everest-core /ext/source &&\
             cp /ext/source/.ci/build-kit/compile.sh /ext/scripts"

ADD install.sh /ext/scripts
RUN /entrypoint.sh run-script compile

# Don't run the test-and-install script since it deletes the build directory!
RUN /entrypoint.sh run-script install

# Copy over the custom config *after* the compile
ADD config-docker.json dist/share/everest/modules/OCPP/config-docker.json

LABEL org.opencontainers.image.source=https://github.com/us-joet/everest-demo
