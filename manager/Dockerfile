FROM --platform=linux/x86_64 ghcr.io/everest/build-kit-alpine@sha256:7494bd6624aee3f882b4f1edbc589879e1d6d0ccc2c58f3f5c87ac1838ccd1de

ARG EVEREST_VERSION=2024.3.0
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
        # Don't run the test-and-install script since it deletes the build directory!
        && /entrypoint.sh run-script install

#Add lightweight python server to serve ocpp logs formatted as html files
RUN for file in /workspace/build/run-scripts/run-sil*; do \
        echo "python3 -m http.server 9000 --directory /tmp/everest_ocpp_logs &" > temp_file.sh && \
        cat "$file" >> temp_file.sh && \
        mv temp_file.sh "$file" && \
        chmod +x "$file"; \
    done

# Copy over the custom config *after* compilation and installation
COPY config-docker.json ./dist/share/everest/modules/OCPP/config-docker.json
COPY config.json ./dist/share/everest/modules/OCPP201/config.json
COPY device_model_storage_maeve_sp1.db ./dist/share/everest/modules/OCPP201/device_model_storage.db

COPY run-test.sh /ext/source/tests/run-test.sh

LABEL org.opencontainers.image.source=https://github.com/everest/everest-demo
