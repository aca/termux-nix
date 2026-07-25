{ ... }: {
  # lxterminal reads this INI at startup; unspecified keys fall back to
  # defaults. Colors mirror ~/.Xresources (special + color0-15). Note: the
  # file is a read-only nix symlink, so GUI Preferences changes won't save —
  # edit here instead.
  xdg.configFile."lxterminal/lxterminal.conf".text = ''
    [general]
    hidescrollbar=true
    hidemenubar=true
    color_preset=Custom
    bgcolor=rgb(0,0,0)
    fgcolor=rgb(241,252,248)
    palette_color_0=rgb(59,59,59)
    palette_color_1=rgb(224,85,97)
    palette_color_2=rgb(140,194,101)
    palette_color_3=rgb(229,192,123)
    palette_color_4=rgb(74,165,240)
    palette_color_5=rgb(193,98,222)
    palette_color_6=rgb(66,179,194)
    palette_color_7=rgb(215,218,224)
    palette_color_8=rgb(92,99,112)
    palette_color_9=rgb(255,97,110)
    palette_color_10=rgb(165,224,117)
    palette_color_11=rgb(240,198,116)
    palette_color_12=rgb(77,196,255)
    palette_color_13=rgb(222,115,255)
    palette_color_14=rgb(76,209,224)
    palette_color_15=rgb(255,255,255)
    fontname=IosevkaTermSlab Nerd Font Mono 14
    disallowbold=false
    boldbright=false
    cursorblinks=false
    cursorunderline=false
    audiblebell=false
    visualbell=false
    tabpos=top
    scrollback=0
    geometry_columns=80
    geometry_rows=24
    hideclosebutton=true
    hidepointer=false
    selchars=-A-Za-z0-9,./?%&#:_~
    disablef10=false
    disablealt=false
    disableconfirm=false
    tabwidth=100

    [shortcut]
    zoom_in_accel=<Primary>equal
    zoom_out_accel=<Primary>minus
    new_window_accel=<Primary><Shift>n
    new_tab_accel=<Primary><Shift>t
    close_tab_accel=<Primary><Shift>w
    close_window_accel=<Primary><Shift>q
    copy_accel=<Primary><Shift>c
    paste_accel=<Primary><Shift>v
    name_tab_accel=<Primary><Shift>i
    previous_tab_accel=<Primary>Page_Up
    next_tab_accel=<Primary>Page_Down
    move_tab_left_accel=<Primary><Shift>Page_Up
    move_tab_right_accel=<Primary><Shift>Page_Down
    zoom_reset_accel=<Primary><Shift>parenright
  '';
}
