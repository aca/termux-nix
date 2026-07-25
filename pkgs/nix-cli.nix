{ lib, ... }:
let
  # Forwarder: a termux-level `nix` (and friends) that transparently runs the
  # real nix inside the proot-distro `nix` container. argv[0] picks the command,
  # so the same body serves nix / nix-shell / nix-build / nix-env.
  #
  # --shared-tmp binds the whole termux $PREFIX/tmp as the container /tmp —
  # including the termux-x11 socket (/tmp/.X11-unix), so GUI apps launched via
  # nix render on the native termux-x11 (:0) i3 desktop, and tmp files flow
  # both ways between termux and the container.
  # proot-distro >= 4 (python rewrite) already binds the termux app dirs
  # ($HOME, $PREFIX, storage) into normal containers, so only bind the
  # caller's cwd when it lies outside those — a duplicate bind prints
  # overlap warnings. cd there so `nix build .`, `nix-shell` etc. operate
  # on the termux working directory instead of the container's /root.
  forwarder = ''
    #!/data/data/com.termux/files/usr/bin/sh
    cmd=$(basename "$0")
    d=$PWD
    case "$d" in
      /data/data/com.termux/*|/storage/*|/sdcard/*) bind="" ;;
      *) bind="--bind=$d:$d" ;;
    esac
    exec proot-distro login nix --shared-tmp \
      ''${bind:+"$bind"} \
      -- sh -c 'cd "$2" 2>/dev/null; c=$1; shift 2; exec env DISPLAY=:0 "$c" "$@"' sh "$cmd" "$d" --extra-experimental-features "nix-command flakes" "$@"
  '';

  mkForwarder = {
    text = forwarder;
    executable = true;
  };
in
{
  home.file = {
    ".local/bin/nix" = mkForwarder;
    ".local/bin/nix-shell" = mkForwarder;
    ".local/bin/nix-build" = mkForwarder;
    ".local/bin/nix-env" = mkForwarder;
  };
}
