#!/bin/sh

cd /ext/source \
&& mkdir build \
&& cd build \
&& cmake -DBUILD_TESTING=ON ..\
&& make install -j6 \
&& make install_everest_testing \
