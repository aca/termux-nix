{ lib, ... }:
let
  # Termux native packages, installed by `termux-nix switch` via `pkg install`.
  # pkg list-all
  packages = [
    # bootstrap deps of `termux-nix switch` itself (also installed by the
    # first-switch bootstrap in ./termux-nix; proot-distro comes via pip there)
    "openssh"
    "rsync"

    "fish"
    "termux-services"
    # required by the termux-x11 runit service (pkgs/services.nix) and the
    # start-desktop-* scripts
    "termux-x11-nightly"
    # Xvfb for the xvfb runit service (pkgs/services.nix): headless :0 when
    # the desktop is off
    # "xorg-server-xvfb"
    # turnip vulkan driver for adreno; mesa defaults GL to zink on top of it,
    # without it GL falls back to llvmpipe (software)
    "mesa-vulkan-icd-freedreno"

    "i3"
    "i3status"
    "lxqt"
    "openbox"

    "libnotify"
    "rofi"
    "xsel"
    "bat"
    "git"
    "vim"
    "fzf"
    "tmux"
    "chromium"
    "chromium-host-tools"
    "mupdf"
    "gawk"
    "pulseaudio"
    "lxterminal"
    "konsole"
    "xscreensaver"
    "python"
    "python-pip"

    # "flameshot"
    # "ghq"
  ];

  pipPackages = [
    # bspwm-style auto split for i3 (pure python, runs on native termux python)
    "autotiling"
  ];

  # termux app config. enforce-char-based-input: use IME char-based input
  # instead of raw TYPE_NULL — samsung keyboard disables its hardware-key
  # handling (right-alt 한/영 toggle) for TYPE_NULL editors. Unset defaults
  # apply for everything else. Needs `termux-reload-settings` (or app restart).
  termuxProperties = ''
    enforce-char-based-input = true
  '';

  # start termux-x11 server + pulseaudio, then exec the given session command
  mkStartDesktop = session: {
    executable = true;
    text = ''
      #!/data/data/com.termux/files/usr/bin/sh
      # start termux-x11 server (runit service, pkgs/services.nix) + session.
      # The service owns the X server — never spawn/pkill a loader here, that
      # fights runsv (it restarts whatever pkill kills, and the extra loader
      # crash-loops on the taken :0, resetting the app's input every 2s).
      export SVDIR=/data/data/com.termux/files/usr/var/service
      # xvfb no longer used — termux-x11 owns :0 from boot
      # sv down xvfb 2>/dev/null
      # if pgrep -x Xvfb >/dev/null 2>&1; then
      #   pkill -x Xvfb 2>/dev/null
      #   i=0; while [ -e /data/data/com.termux/files/usr/tmp/.X11-unix/X0 ] && [ $i -lt 25 ]; do
      #     sleep 0.2; i=$((i+1))
      #   done
      # fi
      # the boot-started i3 service (pkgs/services.nix) holds the WM slot on
      # :0 — stop it before this session takes over
      sv down i3 2>/dev/null
      pkill -x i3 2>/dev/null
      sv up termux-x11 2>/dev/null
      i=0; until [ -e /data/data/com.termux/files/usr/tmp/.X11-unix/X0 ] || [ $i -ge 20 ]; do
        sleep 0.5; i=$((i+1))
      done
      am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
      pulseaudio --start --exit-idle-time=-1
      # turnip's kgsl backend (samsung kernel) has no GPU timestamp support and
      # assert-aborts when GL timer queries are used — mask those extensions so
      # apps that probe them (chromium) don't crash the GPU process
      export MESA_EXTENSION_OVERRIDE="-GL_ARB_timer_query -GL_EXT_timer_query -GL_EXT_disjoint_timer_query"
      # picked up by the chromium-browser launcher: hardware accel via
      # ANGLE-on-GLES -> zink -> turnip (--use-angle=vulkan fails: chromium's
      # bundled ANGLE wants vulkan instance extensions turnip doesn't have)
      export CHROMIUM_USER_FLAGS="--use-angle=gles --ignore-gpu-blocklist --disable-gpu-sandbox"
      exec env DISPLAY=:0 ${session}
    '';
  };
in
{
  xdg.configFile."termux-nix/packages.txt".text = lib.concatStringsSep "\n" packages + "\n";

  # pip packages, installed natively by `termux-nix switch` (pure-python tools
  # like autotiling that talk to i3 over IPC — no proot needed)
  xdg.configFile."termux-nix/pip.txt".text = lib.concatStringsSep "\n" pipPackages + "\n";

  home.file.".termux/termux.properties".text = termuxProperties;

  # i3 runs as a runit service from boot (pkgs/services.nix) — this only makes
  # sure the services are up and brings the termux-x11 activity to front
  home.file.".local/bin/start-desktop-i3" = {
    executable = true;
    text = ''
      #!/data/data/com.termux/files/usr/bin/sh
      export SVDIR=/data/data/com.termux/files/usr/var/service
      sv up termux-x11 2>/dev/null
      i=0; until [ -e /data/data/com.termux/files/usr/tmp/.X11-unix/X0 ] || [ $i -ge 20 ]; do
        sleep 0.5; i=$((i+1))
      done
      sv up i3 2>/dev/null
      am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
      pulseaudio --start --exit-idle-time=-1
    '';
  };

  home.file.".local/bin/start-desktop-lxqt" =
    mkStartDesktop "dbus-launch --exit-with-session startlxqt";

  home.file.".local/bin/stop-desktop" = {
    executable = true;
    text = ''
      #!/data/data/com.termux/files/usr/bin/sh
      # stop session (i3/lxqt) + termux-x11 server + pulseaudio (managed by termux-nix)
      # service down FIRST so runsv doesn't restart what pkill kills; the pkill
      # then also reaps any stray process not started by runsv
      export SVDIR=/data/data/com.termux/files/usr/var/service
      sv down i3 2>/dev/null
      pkill i3
      pkill lxqt-session
      sv down termux-x11 2>/dev/null
      pkill termux-x11
      am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1
      pulseaudio --kill 2>/dev/null
      # xvfb no longer used — nothing takes :0 back; next termux boot (or
      # start-desktop-i3) brings termux-x11 + i3 up again
      # sv up xvfb 2>/dev/null
    '';
  };
}
