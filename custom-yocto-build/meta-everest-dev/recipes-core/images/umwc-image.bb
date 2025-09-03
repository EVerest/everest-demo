require recipes-core/images/core-image-base.bb

SUMMARY = "EVerest image for Yeti and Yak reference hardware"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
# inherit boot_image
INHERIT += "populate_sdk"


CORE_IMAGE_EXTRA_INSTALL += "\
        python3 \
        python3-dev \
        python3-pip \
        python3-ply \
        python3-cffi \
        python3-asyncio-glib \
        python3-cryptography \
        python3-psutil \
        python3-netifaces \
        python3-dateutil \
        python3-iso15118 \
        python3-sqlite3 \
        vim \
        sqlite3 \
        everest-core \
        everest-admin-panel \
        stm32flash \
        everest-yeti-yak \
        libocpp \
        mosquitto \
        fontconfig \
        tzdata \
        screen \
        openssh \
        nano \
        htop \
        lsof \
        minicom \
        util-linux \
        coreutils \
        iproute2 \
        tree \
        curl \
	perf \
        systemd-analyze \
        fbida \
	"

COMPATIBLE_MACHINE = "^rpi$"
IMAGE_INSTALL:append = " packagegroup-rpi-test packagegroup-core-buildessential"
IMAGE_INSTALL:append = " gfortran gfortran-symlinks libgfortran libgfortran-dev"

# Not sure if needed
DISABLE_SPLASH = "1"
DISABLE_RPI_BOOT_LOGO = "1"

IMAGE_INSTALL:remove = " psplash"
IMAGE_FEATURES:remove = " splash "

WKS_FILE="sdimage-raspberrypi.wks"
ENABLE_UART="1"
