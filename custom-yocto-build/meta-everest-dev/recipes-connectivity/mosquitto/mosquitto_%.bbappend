FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://mosquitto.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/mosquitto
    install -m 0755 ${WORKDIR}/mosquitto.conf ${D}${sysconfdir}/mosquitto/mosquitto.conf
}
