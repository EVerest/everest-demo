#!/bin/sh
ninja -j$(nproc) -C build install

# install everestpy via cmake target from everest-framework
ninja -C build everestpy_pip_install_dist
ninja -C build install_everest_testing
