{ ... }: {
  # LXQt session config. window_manager picks the WM lxqt-session launches —
  # openbox instead of the kwin default. Like lxterminal.conf, this is a
  # read-only nix symlink: the "Session Settings" GUI won't save — edit here.
  xdg.configFile."lxqt/session.conf".text = ''
    [General]
    window_manager=openbox
  '';

  # XDG autostart override (same filename as the system entry, Hidden=true):
  # keeps lxqt-session from launching powermanagement — broken on termux
  # (libKF6Solid needs libmount.so, which termux doesn't ship natively).
  xdg.configFile."autostart/lxqt-powermanagement.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=LXQt Power Management
    Exec=lxqt-powermanagement
    X-LXQt-Module=true
    Hidden=true
  '';
}
