{ ... }: {
  # gnome-terminal keeps its settings in dconf (binary db), not a config file.
  # Declared here as a dconf keyfile; switch.sh applies it with
  # `dconf load /org/gnome/terminal/legacy/`. GUI Preferences changes are
  # overwritten on the next switch — edit here instead.
  # Colors + font mirror lxterminal.nix (~/.Xresources palette).
  xdg.configFile."termux-nix/gnome-terminal.dconf".text = ''
    [/]
    default-show-menubar=false
    theme-variant='dark'

    [profiles:]
    default='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'
    list=['b1dcc9dd-5262-4d8d-a863-c897e6d979b9']

    [profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
    visible-name='termux-nix'
    use-theme-colors=false
    background-color='#000000'
    foreground-color='#F1FCF8'
    palette=['#3B3B3B', '#E05561', '#8CC265', '#E5C07B', '#4AA5F0', '#C162DE', '#42B3C2', '#D7DAE0', '#5C6370', '#FF616E', '#A5E075', '#F0C674', '#4DC4FF', '#DE73FF', '#4CD1E0', '#FFFFFF']
    use-system-font=false
    font='IosevkaTermSlab Nerd Font Mono 14'
    cursor-blink-mode='off'
    audible-bell=false
    scrollbar-policy='never'
  '';
}
