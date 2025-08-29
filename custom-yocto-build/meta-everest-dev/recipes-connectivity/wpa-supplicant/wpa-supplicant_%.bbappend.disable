FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
        file://umwc-wifi.conf \
        file://wpa_supplicant_hotspot.service \
"

do_install:append() {
	install -d ${D}${sysconfdir}
        install -m 600 ${WORKDIR}/umwc-wifi.conf ${D}${sysconfdir}/wpa_supplicant.conf

	if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
		install -d ${D}/${systemd_system_unitdir}
		install -m 644 ${WORKDIR}/wpa_supplicant_hotspot.service ${D}/${systemd_system_unitdir}/wpa_supplicant.service
	fi
}

