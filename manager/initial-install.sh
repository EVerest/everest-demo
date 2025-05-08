git clone https://github.com/EVerest/everest-core.git
cd everest-core
git checkout ${EVEREST_VERSION}
cd ..
mkdir -p /ext/scripts
cp -r everest-core/.ci/build-kit/scripts/* /ext/scripts/
mv everest-core /ext/source
bash /tmp/demo-patch-scripts/apply-compile-patches.sh

echo "Installing python to allow the power_curve to run"
pip install --break-system-packages numpy==2.1.3
pip install --break-system-packages control==0.10.1
pip install --break-system-packages paho-mqtt==2.1.0
