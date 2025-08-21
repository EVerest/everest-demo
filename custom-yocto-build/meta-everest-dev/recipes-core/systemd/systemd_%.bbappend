FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://20-wired.network \
"

FILES:${PN} += " \
    ${sysconfdir}/systemd/network/20-wired.network \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/20-wired.network ${D}${sysconfdir}/systemd/network
}
