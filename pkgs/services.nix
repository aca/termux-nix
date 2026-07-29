{ lib, ... }:
let
  # Termux runit services (termux-services). Declared here, materialized by
  # switch.sh into $PREFIX/var/service/<name>: a real dir (runsv writes its
  # supervise/ state there) with run symlinked to the home-managed script.
  # run scripts are read natively — bare command names only, no /nix/store.
  # enable = false keeps the service stopped via runit's down file (and switch
  # stops it); it overrides any runtime sv-enable/sv-disable on declared ones.
  services = {
    termux-x11 = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        exec termux-x11 :0 2>&1
      '';
    };
    sshd = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        exec sshd -D -e 2>&1
      '';
    };
    clipsync = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        export DISPLAY=:0
        exec /data/data/com.termux/files/home/.local/bin/clipsync sync root:4445
      '';
    };
  };
in
{
  home.file = builtins.listToAttrs (lib.flatten (lib.mapAttrsToList (name: svc:
    [ (lib.nameValuePair ".config/termux-nix/service/${name}/run" {
        text = svc.run;
        executable = true;
      }) ]
    ++ lib.optional (!svc.enable)
      (lib.nameValuePair ".config/termux-nix/service/${name}/down" { text = ""; })
  ) services));
}
