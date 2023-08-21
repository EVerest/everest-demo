#FROM everest-demo-build-kit-debian:latest
FROM ghcr.io/everest/build-kit-alpine:latest

RUN echo "Building demo docker image"

# ADD https://github.com/EVerest/run-clang-format/releases/download/clang-format-16/clang-format \
#     /usr/bin/clang-format
# RUN chmod +x /usr/bin/clang-format

# RUN git clone -b v1.0.0 https://@github.com/EVerest/run-clang-format.git
# RUN cp run-clang-format/run-clang-format.py /usr/bin/run-clang-format

# RUN echo "Running clang now..."
# RUN /usr/bin/run-clang-format . --extensions "hpp,cpp" -e ./cache -r

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

# ENTRYPOINT ["./build/run-scripts/run-sil.sh"]
ENTRYPOINT ["tail -f /dev/null"]
