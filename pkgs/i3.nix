{
  # Raw i3 config. All commands are bare names resolved via termux PATH —
  # never reference nix store paths here (switch rejects them).
  xdg.configFile."i3/config".text = ''
    hide_edge_borders none
    smart_borders on

    set $mod Mod4
    bindsym $mod+Control+Shift+Right move workspace to output right
    bindsym $mod+Control+Shift+Left move workspace to output left
    bindsym $mod+Control+Shift+Down move workspace to output down
    bindsym $mod+Control+Shift+Up move workspace to output up

    bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume "@DEFAULT_SINK@" "-5%"
    bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute "@DEFAULT_SINK@" toggle
    bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume "@DEFAULT_SINK@" "+5%"

    set $left h
    set $down j
    set $up k
    set $right l
    set $term lxterminal

    default_border pixel 0
    smart_gaps on

    # bspwm-style spiral: auto splith/splitv by window aspect ratio
    # (native pip package; runs only on restart, not on config reload)
    exec_always --no-startup-id autotiling

    bindsym $mod+x exec $term
    bindsym $mod+Return exec --no-startup-id rofi -modes combi -show combi -font 'IBM Plex Sans KR 12'

    # Kill focused window
    bindsym $mod+q kill
    bindsym Mod1+q kill

    # Reload the configuration file
    bindsym $mod+Shift+c reload

    # Move your focus around
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    # Or use $mod+[up|down|left|right]
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # Move the focused window with the same, but add Shift
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    # Ditto, with arrow keys
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    bindsym $mod+bracketright focus output right
    bindsym $mod+bracketleft focus output left

    # screenshot: region select, annotate, enter=copy ctrl+s=save
    bindsym $mod+p exec --no-startup-id flameshot gui

    bindsym $mod+f fullscreen

    # splits
    bindsym $mod+Shift+apostrophe splith
    bindsym $mod+s splitv

    # Toggle the current focus between tiling and floating mode
    bindsym $mod+Shift+space floating toggle

    # Move focus to the parent container
    bindsym $mod+a focus parent

    # Resizing containers:
    mode "resize" {
        # left will shrink the containers width
        # right will grow the containers width
        # up will shrink the containers height
        # down will grow the containers height
        bindsym $left resize shrink width 10px
        bindsym $down resize grow height 10px
        bindsym $up resize shrink height 10px
        bindsym $right resize grow width 10px

        # Ditto, with arrow keys
        bindsym Left resize shrink width 10px
        bindsym Down resize grow height 10px
        bindsym Up resize shrink height 10px
        bindsym Right resize grow width 10px

        # Return to default mode
        bindsym Return mode "default"
        bindsym Escape mode "default"
    }
    bindsym $mod+z mode "resize"

    # Status Bar:
    bar {
        position bottom
        mode hide

        colors {
            statusline #ffffff
            background #323232
            inactive_workspace #32323200 #32323200 #5c5c5c
        }
    }

    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8

    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10

    bindsym $mod+b exec --no-startup-id xscreensaver-command -activate
  '';

  # i3lock-like: instant black blank on $mod+b, any input dismisses. termux
  # builds xscreensaver with --disable-locking (no PAM on android), so this is
  # a visual cover only — the android lockscreen is the real security boundary.
  home.file.".xscreensaver".text = ''
    mode: blank
    timeout: 2:00:00
    lock: False
    splash: False
    fade: False
    unfade: False
    dpmsEnabled: False
  '';
}
