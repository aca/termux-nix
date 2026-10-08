# termux-packages recipe — rxvt-unicode is NOT in the termux repos, so this
# builds it as a custom termux deb (native bionic binary, no proot).
#
# rebuild on the PC:
#   git clone --depth 1 https://github.com/termux/termux-packages
#   cp -r termux-pkgs/rxvt-unicode termux-packages/x11-packages/
#   cd termux-packages && bash ./scripts/run-docker.sh ./build-package.sh -I -a aarch64 rxvt-unicode
# install on the device:
#   scp termux-packages/output/rxvt-unicode_*_aarch64.deb termux:
#   ssh termux 'apt install -y ./rxvt-unicode_*_aarch64.deb'
# config lives in pkgs/rxvt-unicode.nix (~/.Xdefaults).

TERMUX_PKG_HOMEPAGE=http://software.schmorp.de/pkg/rxvt-unicode.html
TERMUX_PKG_DESCRIPTION="A clone of rxvt with Unicode and Xft support (urxvt)"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@aca"
# 9.26 is the last release with libptytty bundled (9.30+ needs it as a
# separate package); the CVE-2022-4170 perl background ext is disabled anyway
TERMUX_PKG_VERSION="9.26"
TERMUX_PKG_SRCURL=http://dist.schmorp.de/rxvt-unicode/Attic/rxvt-unicode-$TERMUX_PKG_VERSION.tar.bz2
TERMUX_PKG_SHA256=643116b9a25d29ad29f4890131796d42e6d2d21312282a613ef66c80c5b8c98b
TERMUX_PKG_DEPENDS="fontconfig, freetype, libx11, libxft, libxrender, libc++"
# terminfo (rxvt-unicode-256color) is already shipped by termux's ncurses
TERMUX_PKG_RM_AFTER_INSTALL="share/terminfo"
# no utmp/wtmp/lastlog on android; perl off (keeps closure small, cross-perl
# is painful); pixbuf/startup-notification would pull gtk-world deps
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--enable-256-color
--enable-xft
--enable-font-styles
--enable-unicode3
--enable-combining
--disable-perl
--disable-utmp
--disable-wtmp
--disable-lastlog
--disable-pixbuf
--disable-startup-notification
--with-term=rxvt-unicode-256color
"
