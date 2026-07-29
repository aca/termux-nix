{lib, ... }: {
  imports = [
    ./pkgs/i3.nix
    ./pkgs/i3status.nix
    ./pkgs/dotfiles.nix
    ./pkgs/termux.nix
    ./pkgs/nix-cli.nix
    ./pkgs/nix-apps.nix
    ./pkgs/lxterminal.nix
    ./pkgs/lxqt.nix
    ./pkgs/konsole.nix
    ./pkgs/fonts.nix
    ./pkgs/misc.nix
    ./pkgs/services.nix
  ];

  home.username = "nixos";
  home.homeDirectory = "/data/data/com.termux/files/home";
  home.stateVersion = "26.05";

  # systemd-specific and references the nix store; useless on termux
  xdg.configFile."environment.d/10-home-manager.conf".enable = lib.mkForce false;

  # strip comment lines and blank lines from tmux.conf
  xdg.configFile."tmux/tmux.conf".text = builtins.readFile ./pkgs/tmux.conf;

  home.file.".ssh/config".text = ''
    Include config.d/*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ControlPath /data/data/com.termux/files/usr/tmp/ssh-control-%r@%h:%p
    ControlPersist yes
    TCPKeepAlive yes
    Compression yes
    ControlMaster auto

    ServerAliveInterval 15
    ServerAliveCountMax 3
    HostKeyAlgorithms +ssh-rsa
  '';

  # Slim the on-device closure
  manual.manpages.enable = false;
  manual.html.enable = false;
  manual.json.enable = false;
  news.display = "silent";
  programs.man.enable = false;
}
