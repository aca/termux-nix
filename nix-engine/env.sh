# Shared constants for the termux-nix CLI (PC) and the on-device scripts.
# POSIX sh — sourced by both bash and termux's dash-like sh.
DISTRO=nix
TERMUX_PREFIX=/data/data/com.termux/files/usr
CONTAINER_ROOTFS=$TERMUX_PREFIX/var/lib/proot-distro/containers/$DISTRO/rootfs
STORE_PHYS=$CONTAINER_ROOTFS/nix/store
FLAKE_ATTR=homeConfigurations.termux.activationPackage
