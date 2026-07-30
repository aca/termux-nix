{ lib, ... }:
let
  # Termux runit services (termux-services). Declared here, materialized by
  # switch.sh into $PREFIX/var/service/<name>: a real dir (runsv writes its
  # supervise/ state there) with run symlinked to the home-managed script.
  # run scripts are read natively — bare command names only, no /nix/store.
  # enable = false keeps the service stopped via runit's down file (and switch
  # stops it); it overrides any runtime sv-enable/sv-disable on declared ones.
  # manual = true: switch never forces sv up/down — runtime state is driven by
  # sv (start-desktop/stop-desktop). autostart = false (only with manual)
  # additionally places a down file so runsvdir doesn't start it at boot.
  services = {
    # minimal headless X on :0 so X clients (clipsync) work without the
    # desktop. start-desktop-* takes :0 over (sv down xvfb), stop-desktop
    # gives it back (sv up xvfb).
    xvfb = {
      enable = true;
      manual = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        trap 'kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; exit 0' TERM INT
        Xvfb :0 -screen 0 64x64x8 -nolisten tcp -noreset > /data/data/com.termux/files/usr/tmp/xvfb.log 2>&1 &
        pid=$!
        wait "$pid"
        # crashed or :0 already taken — throttle before runsv retries
        sleep 15
      '';
    };
    # started on demand by start-desktop-* (sv up), not at boot — xvfb owns
    # :0 until then
    termux-x11 = {
      enable = true;
      manual = true;
      autostart = false;
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
    # clipsync-server = {
    #   enable = true;
    #   run = ''
    #     #!/data/data/com.termux/files/usr/bin/sh
    #     export DISPLAY=:0
    #     /data/data/com.termux/files/home/bin/clipsync -backend x11 server :4444 >> /data/data/com.termux/files/usr/tmp/clipsync-server.log 2>&1 || sleep 10
    #   '';
    # };
    # clipsync-android = {
    #   enable = true;
    #   run = ''
    #     #!/data/data/com.termux/files/usr/bin/sh
    #     /data/data/com.termux/files/home/bin/clipsync -backend termux sync :4444 >> /data/data/com.termux/files/usr/tmp/clipsync-android.log 2>&1 || sleep 5
    #   '';
    # };

    clipsync = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        export DISPLAY=:0
        /data/data/com.termux/files/home/bin/clipsync sync root:4445 >> /data/data/com.termux/files/usr/tmp/clipsync.log 2>&1 || sleep 10
      '';
    };
  };
in
{
  home.file = builtins.listToAttrs (lib.flatten (lib.mapAttrsToList (name: svc:
    let
      manual = svc.manual or false;
      autostart = svc.autostart or true;
    in
    [ (lib.nameValuePair ".config/termux-nix/service/${name}/run" {
        text = svc.run;
        executable = true;
      }) ]
    ++ lib.optional (!svc.enable || (manual && !autostart))
      (lib.nameValuePair ".config/termux-nix/service/${name}/down" { text = ""; })
    ++ lib.optional (svc.enable && manual)
      (lib.nameValuePair ".config/termux-nix/service/${name}/manual" { text = ""; })
  ) services));
}
