FROM debian:trixie-slim

# add a user to run bitbake
RUN useradd -ms /bin/bash user1

# install dependencies
RUN apt-get update \
    && apt-get --no-install-recommends -y install \
    ca-certificates=20240203 \
    wget=1.21.4-1+b1 \
    patch=2.7.6-7 \
    vim=2:9.1.0016-1 \
    python-is-python3=3.11.4-1 \
    bzip2=1.0.8-5.1 \
    binutils=2.42-4 \
    cpio=2.15+dfsg-1 \
    chrpath=0.16-2+b1 \
    cpp=4:13.2.0-7 \
    diffstat=1.66-1 \
    file=1:5.45-2+b1 \
    g++=4:13.2.0-7 \
    gawk=1:5.2.1-2 \
    git=1:2.43.0-1 \
    lz4=1.9.4-1+b2 \
    make=4.3-4.1 \
    zstd=1.5.5+dfsg2-2 \
    locales=2.37-15 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# add yocto release files
RUN mkdir yocto_release
ADD poky-bf9f2f6f60387b3a7cd570919cef6c4570edcb82.tar.bz2 ./yocto_release
RUN mv ./yocto_release /home/user1/
RUN chown -R user1: /home/user1/yocto_release 

# reconfigure locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8    

# build yocto image
USER user1
WORKDIR /home/user1/yocto_release/poky/
RUN . ./oe-init-build-env && bitbake core-image-minimal
