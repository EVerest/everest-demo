FROM debian:trixie-slim

# add a user to run bitbake
RUN useradd -ms /bin/bash user1

# install dependencies 
RUN apt-get update \
    && apt-get --no-install-recommends -y install \
    tini \
    wget \
    ovmf \
    nginx \
    swtpm \
    procps \
    iptables \
    iproute2 \
    apt-utils \
    dnsmasq \
    net-tools \
    qemu-utils \
    ca-certificates \
    netcat-openbsd \
    qemu-system-x86 \
    && apt-get clean \
    && novnc="1.4.0" \
    && mkdir -p /usr/share/novnc \
    && wget https://github.com/novnc/noVNC/archive/refs/tags/v"$novnc".tar.gz -O /tmp/novnc.tar.gz -q \
    && tar -xf /tmp/novnc.tar.gz -C /tmp/ \
    && cd /tmp/noVNC-"$novnc" \
    && mv app core vendor package.json *.html /usr/share/novnc \
    && unlink /etc/nginx/sites-enabled/default \
    && sed -i 's/^worker_processes.*/worker_processes 1;/' /etc/nginx/nginx.conf \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install additional dependencies
RUN apt-get update && apt-get install vim python-is-python3 bzip2 binutils cpio chrpath cpp diffstat file g++ gawk git lz4 make zstd -y 

# add yocto release files
RUN mkdir yocto_release
ADD poky-bf9f2f6f60387b3a7cd570919cef6c4570edcb82.tar.bz2 ./yocto_release

# reconfigure locales
RUN apt-get clean && apt-get update && apt-get install -y locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8    

# build yocto image
USER user1
RUN cp -r yocto_release ~/ \
    && cd ~/yocto_release/poky/ \
    && . ./oe-init-build-env \
    && bitbake core-image-minimal
