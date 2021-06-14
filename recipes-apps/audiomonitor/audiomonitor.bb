#
# This file is the audioMonitor recipe.
#

SUMMARY = "Simple audiomonitor application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS+= "axisfifo cpprest"

SRC_URI = "file://Makefile \
	   file://src/main.cpp \
	   file://src/utils.cpp \
	   file://inc/utils.h \
	   file://inc/libs.h \
	   file://inc/axis-fifo.h \
	   file://inc/dj_fft.h \
	   file://www \
		  "

S = "${WORKDIR}"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 audiomonitor ${D}${bindir}
	     mkdir -p ${D}/var/www
             cp -R www/* ${D}/var/www
}

FILES_${PN} += "/var/www"
