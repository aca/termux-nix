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
# separate package). CVE-2022-4170 (background ext reachable via OSC 777):
# 9.26's perl dispatcher only invokes explicitly loaded exts, and our config
# (pkgs/rxvt-unicode.nix) pins perl-ext-common to resize-font only
TERMUX_PKG_VERSION="9.26"
# rev 1: font-step.patch, a no-perl OSC hack for font resizing (dropped)
# rev 2: perl embedding enabled (see termux_step_pre_configure)
# rev 3: vendored resize-font ext (ctrl+-/= bindings in pkgs/rxvt-unicode.nix),
#        font-step.patch removed — resize-font replaces it
TERMUX_PKG_REVISION=3
TERMUX_PKG_SRCURL=http://dist.schmorp.de/rxvt-unicode/Attic/rxvt-unicode-$TERMUX_PKG_VERSION.tar.bz2
TERMUX_PKG_SHA256=643116b9a25d29ad29f4890131796d42e6d2d21312282a613ef66c80c5b8c98b
TERMUX_PKG_DEPENDS="fontconfig, freetype, libx11, libxft, libxrender, libc++, perl"
TERMUX_PKG_BUILD_DEPENDS="perl"
# terminfo (rxvt-unicode-256color) is already shipped by termux's ncurses
TERMUX_PKG_RM_AFTER_INSTALL="share/terminfo"
# no utmp/wtmp/lastlog on android;
# pixbuf/startup-notification would pull gtk-world deps.
# ac_cv_prog_cxx_cxx11 preseeded: autoconf 2.70+'s C++11 conftest clashes
# with bionic's _Nonnull libc decls and wrongly reports "no C++11"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
ac_cv_prog_cxx_cxx11=-std=gnu++11
--enable-256-color
--enable-xft
--enable-font-styles
--enable-unicode3
--enable-combining
--enable-perl
--disable-utmp
--disable-wtmp
--disable-lastlog
--disable-pixbuf
--disable-startup-notification
--with-term=rxvt-unicode-256color
"

termux_step_post_get_source() {
	# rclock (bundled clock app) needs libXt headers — drop it from the build
	sed -i -e 's/^allbin: rxvt rxvtd rxvtc rclock/allbin: rxvt rxvtd rxvtc/' \
		-e '/INSTALL_PROGRAM) rclock/d' src/Makefile.in
}

termux_step_pre_configure() {
	# cross-perl embedding: configure asks $PERL -MExtUtils::Embed for
	# ccopts/ldopts, which would describe the build-host perl. Fake those two
	# queries with the target layout (termux perl ships $PREFIX/include/perl
	# -> CORE and $PREFIX/lib/libperl.so); everything else (version probe,
	# xsubpp codegen, Pod::Man) runs fine on the host perl.
	export PERL=$TERMUX_PKG_TMPDIR/perl-wrapper
	cat > "$PERL" <<-EOF
		#!/bin/sh
		case "\$*" in
		*ExtUtils::Embed*ccopts*) echo "-I$TERMUX_PREFIX/include/perl" ;;
		*ExtUtils::Embed*ldopts*) echo "-L$TERMUX_PREFIX/lib -lperl" ;;
		*) exec perl "\$@" ;;
		esac
	EOF
	chmod +x "$PERL"
}

termux_step_post_make_install() {
	# resize-font: vendored from simmel/urxvt-resize-font @ b593580 (ISC);
	# font size keybindings, configured via URxvt.resize-font.* resources
	install -Dm644 "$TERMUX_PKG_BUILDER_DIR"/resize-font \
		"$TERMUX_PREFIX"/lib/urxvt/perl/resize-font
}
