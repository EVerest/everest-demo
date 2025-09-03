
do_install:append () {
    mkdir -p ${D}${sysconfdir}/sudoers.d
    echo "%sudo ALL=(ALL) ALL" > ${D}${sysconfdir}/sudoers.d/001_first
}
