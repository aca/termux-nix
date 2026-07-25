#!/data/data/com.termux/files/usr/bin/sh
# Bootstrap of the proot-distro nix container (runs on the device). Idempotent;
# `termux-nix switch` runs this on every switch (install is skipped when the
# container exists, the nix.conf block is re-applied each time).
# Installs the official nixos/nix docker image and configures nix.conf so that
# `nix` pulls prebuilt binaries from cache.nixos.org and never builds on-device.
set -eu

DISTRO=nix

if ! proot-distro list --installed 2>/dev/null | grep -q "^${DISTRO}$" &&
   ! proot-distro login "$DISTRO" -- true 2>/dev/null; then
    echo ">> installing $DISTRO container (nixos/nix image)"
    proot-distro install nixos/nix
fi

echo ">> configuring /etc/nix/nix.conf"
proot-distro login "$DISTRO" -- sh -c '
conf=/etc/nix/nix.conf
# drop our managed block if present, then re-append (idempotent)
sed -i "/# termux-nix managed/,\$d" "$conf" 2>/dev/null || true
cat >>"$conf" <<EOF
# termux-nix managed
experimental-features = nix-command flakes
substituters = https://cache.nixos.org
max-jobs = 1
EOF
'

# map the bare `nixpkgs` flake ref to the locked input's source store path
# (pushed by `termux-nix switch`) — otherwise it means nixpkgs-unstable and
# `nix run nixpkgs#x` downloads the source plus everything under different
# hashes. Also gc-root the source so `termux-nix gc` keeps it.
if [ -n "${TN_NIXPKGS_SRC:-}" ]; then
    echo ">> pinning flake registry: nixpkgs -> $TN_NIXPKGS_SRC"
    proot-distro login "$DISTRO" -- sh -c '
        nix registry add nixpkgs "path:$1"
        mkdir -p /nix/var/nix/gcroots
        ln -sfn "$1" /nix/var/nix/gcroots/termux-nix-nixpkgs
    ' sh "$TN_NIXPKGS_SRC"
fi

echo ">> done. try: nix run nixpkgs#hello"
