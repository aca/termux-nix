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
    # xvfb (headless :0 while the desktop is off) replaced by running
    # termux-x11 + i3 from boot — X clients (xclip, clipsync) always have :0.
    # xvfb = {
    #   enable = true;
    #   manual = true;
    #   run = ''
    #     #!/data/data/com.termux/files/usr/bin/sh
    #     trap 'kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; exit 0' TERM INT
    #     Xvfb :0 -screen 0 64x64x8 -nolisten tcp -noreset > /data/data/com.termux/files/usr/tmp/xvfb.log 2>&1 &
    #     pid=$!
    #     wait "$pid"
    #     # crashed or :0 already taken — throttle before runsv retries
    #     sleep 15
    #   '';
    # };
    # started at boot by runsvdir; owns :0 permanently. The app activity is
    # only brought up by start-desktop-i3 — the server (and clipboard for
    # xclip) works without it.
    termux-x11 = {
      enable = true;
      manual = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        exec termux-x11 :0 2>&1
      '';
    };
    # i3 session on :0, started at boot alongside termux-x11.
    # start-desktop-i3 only shows the activity; stop-desktop svs this down.
    i3 = {
      enable = true;
      manual = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        # wait for the termux-x11 service to bring up :0
        i=0; until [ -e /data/data/com.termux/files/usr/tmp/.X11-unix/X0 ] || [ $i -ge 20 ]; do
          sleep 0.5; i=$((i+1))
        done
        # :0 never came up — throttle before runsv retries
        [ -e /data/data/com.termux/files/usr/tmp/.X11-unix/X0 ] || { sleep 10; exit 1; }
        # launch the termux-x11 app too — it does the X<->android clipboard
        # sync, which needs the activity alive (no-op if already running)
        am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
        export DISPLAY=:0
        # turnip's kgsl backend (samsung kernel) has no GPU timestamp support and
        # assert-aborts when GL timer queries are used — mask those extensions so
        # apps that probe them (chromium) don't crash the GPU process
        export MESA_EXTENSION_OVERRIDE="-GL_ARB_timer_query -GL_EXT_timer_query -GL_EXT_disjoint_timer_query"
        # picked up by the chromium-browser launcher: hardware accel via
        # ANGLE-on-GLES -> zink -> turnip (--use-angle=vulkan fails: chromium's
        # bundled ANGLE wants vulkan instance extensions turnip doesn't have)
        export CHROMIUM_USER_FLAGS="--use-angle=gles --ignore-gpu-blocklist --disable-gpu-sandbox"
        exec i3 2>&1
      '';
    };
    sshd = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        exec sshd -D -e 2>&1
      '';
    };

    clipsync-server = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        export DISPLAY=:0
        /data/data/com.termux/files/home/bin/clipsync -backend x11 serve :4444 >> /data/data/com.termux/files/usr/tmp/clipsync-server.log 2>&1 || sleep 10
      '';
    };

    clipsync-android = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        /data/data/com.termux/files/home/bin/clipsync -backend termux sync :4444 >> /data/data/com.termux/files/usr/tmp/clipsync-android.log 2>&1 || sleep 5
      '';
    };

    clipsync-termux-x11 = {
      enable = true;
      run = ''
        #!/data/data/com.termux/files/usr/bin/sh
        export DISPLAY=:0
        /data/data/com.termux/files/home/bin/clipsync sync root:4444 >> /data/data/com.termux/files/usr/tmp/clipsync.log 2>&1 || sleep 10
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
