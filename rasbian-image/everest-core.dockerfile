FROM ubuntu:latest

RUN apt update && apt-get install sudo curl -y

# setup clang format
RUN apt install clang-format-12 -y
RUN update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-12 100 

# setup nodejs v21
RUN curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - && sudo apt-get install -y nodejs

# install dependencies
RUN sudo apt install -y python3-pip git rsync wget cmake doxygen graphviz build-essential clang-tidy cppcheck openjdk-17-jdk \
    libboost-all-dev libssl-dev libsqlite3-dev rfkill libpcap-dev libevent-dev pkg-config libcap-dev
# note, removed the following packages from this command: npm docker docker-compose nodejs curl

# install python dependencies
RUN python3 -m pip install --upgrade pip setuptools wheel jstyleson jsonschema

# download EDM source files
RUN git clone https://github.com/EVerest/everest-dev-environment.git

# install EDM
RUN cd everest-dev-environment/dependency_manager && python3 -m pip install .

# add /home/USER/.local/bin and CPM_SOURCE_CACHE to $PATH
ENV PATH=$PATH:/home/$(whoami)/.local/bin
ENV CPM_SOURCE_CACHE=$HOME/.cache/CPM

# setup EVerest workspace:
RUN cd everest-dev-environment/dependency_manager && edm init --workspace ~/checkout/everest-workspace

# install ev-cli
RUN cd ~/checkout/everest-workspace/everest-utils/ev-dev-tools && python3 -m pip install .

# install the required packages for ISO15118 communication
RUN cd ~/checkout/everest-workspace/Josev && python3 -m pip install -r requirements.txt

# build EVerest
RUN mkdir -p ~/checkout/everest-workspace/everest-core/build \
    && cd ~/checkout/everest-workspace/everest-core/build \
    && cmake .. \
    && make install

# download and untar the bullseye-toolchain
RUN wget http://build.pionix.de:8888/release/toolchains/bullseye-toolchain.tgz && tar xfz bullseye-toolchain.tgz

# cross-compile by changing the given paths accordingly and build EVerest
RUN cd ~/checkout/everest-workspace/everest-core \
    && cmake \
    -DCMAKE_TOOLCHAIN_FILE=/full-path-to/bullseye-toolchain/toolchain.cmake \
    -DCMAKE_INSTALL_PREFIX=/mnt/user_data/opt/everest \
    -S . -B build-cross \
    && make -j$(nproc) -C build-cross \
    && make -j$(nproc) DESTDIR=./dist -C build-cross install

ENTRYPOINT ["/bin/bash"]