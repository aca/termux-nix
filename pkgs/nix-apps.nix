{
  pkgs,
  lib,
  pkgsUnstable,
  ...
}:
let
  # Declare nixpkgs apps to expose on the termux PATH. `bin` is the command name
  # you type; `drv` is the package providing it. For each one home-manager writes
  # a native shell forwarder to ~/.local/bin/<bin> that runs the app's binary
  # under a BARE proot whose root stays the termux filesystem — only /nix is bound
  # (for the binary's glibc interpreter/libs). So the termux cwd is preserved
  # naturally (no home/cwd bind) and it feels like running the executable直接.
  #
  # The apps' closures become part of this generation, so `termux-nix switch`
  # ships them to the device automatically — no separate install, no `nix run` eval.
  # bare proot has no /etc/fonts; point GUI apps at a generated fontconfig that
  # lists nix font dirs, else chromium renders no text ("Fontconfig error").
  #
  # GTK app: FONTCONFIG_FILE so text renders (bare proot has no /etc/fonts)
  fontsConf = pkgs.makeFontsConf {
    fontDirectories = [
      pkgs.dejavu_fonts
      pkgs.liberation_ttf
      # pkgs.noto-fonts-color-emoji
      pkgs.noto-fonts-cjk-sans
      pkgs.ibm-plex
    ];
  };

  apps = [
    {
      bin = "remmina";
      drv = pkgs.remmina;
      env = "FONTCONFIG_FILE=${fontsConf}";
    }
    {
      bin = "zathura";
      drv = pkgs.zathura.override {
        plugins = [
          pkgs.zathuraPkgs.zathura_cb
          pkgs.zathuraPkgs.zathura_pdf_poppler
          pkgs.zathuraPkgs.zathura_pdf_mupdf
        ];
      };
      env = "FONTCONFIG_FILE=${fontsConf}";
    }
    # {
    #   bin = "vivaldi";
    #   drv = pkgs.vivaldi.override { proprietaryCodecs = true; };
    #   args = "--no-sandbox --disable-dev-shm-usage --disable-gpu";
    #   env = "FONTCONFIG_FILE=${fontsConf}";
    # }

    # cli applications
    {
      bin = "ghq";
      drv = pkgs.ghq;
    }
    # {
    #   # cgo needs a C toolchain: go runs $CC for compile/link, and the nixpkgs
    #   # gcc wrapper reaches glibc headers and binutils by absolute path, so
    #   # nothing else has to be on the termux PATH.
    #   bin = "go";
    #   drv = pkgs.go;
    #   env = "CC=${pkgs.gcc}/bin/gcc";
    # }
    # {
    #   bin = "gopls";
    #   drv = pkgs.gopls;
    # }
    # {
    #   bin = "gofumpt";
    #   drv = pkgs.gofumpt;
    # }
    {
      # from master: claude-code updates land there long before the release
      bin = "claude";
      drv = pkgsUnstable.claude-code;
    }
  ];

  rootfs = "/data/data/com.termux/files/usr/var/lib/proot-distro/containers/nix/rootfs";
  tmp = "/data/data/com.termux/files/usr/tmp";

  forwarder = app: {
    name = ".local/bin/${app.bin}";
    value = {
      executable = true;
      # -u LD_PRELOAD: termux injects a bionic ld-preload that breaks glibc.
      # /tmp bind: android has no /tmp, so the whole termux $PREFIX/tmp serves
      # as it — that carries the termux-x11 socket (/tmp/.X11-unix), so with
      # DISPLAY set GUI apps render on the termux-x11 (:0) i3 desktop.
      # resolv.conf bind: android has no /etc/resolv.conf (bionic asks the
      # platform resolver, which knows the tailscale VPN DNS) — glibc apps need
      # one, so bind ours with tailscale (100.100.100.100) first.
      text = ''
        #!/data/data/com.termux/files/usr/bin/sh
        exec env -u LD_PRELOAD DISPLAY=:0 ${app.env or ""} proot \
          -b "${rootfs}/nix:/nix" \
          -b "${tmp}:/tmp" \
          -b "$HOME/.config/termux-nix/resolv.conf:/etc/resolv.conf" \
          ${app.drv}/bin/${app.bin} ${app.args or ""} "$@"
      '';
    };
  };
in
{
  home.file = builtins.listToAttrs (map forwarder apps);

  xdg.configFile."termux-nix/apps.txt".text = lib.concatMapStringsSep "\n" (a: a.bin) apps + "\n";

  # tailscale MagicDNS first; public fallback so DNS still works (after the
  # 1s timeout) when tailscale is off. The search domain makes bare tailnet
  # names (`archive-0`) resolve — tailscale's resolver only answers FQDNs.
  xdg.configFile."termux-nix/resolv.conf".text = ''
    nameserver 100.100.100.100
    nameserver 8.8.8.8
    search folk-uaru.ts.net
    options timeout:1
  '';
}
