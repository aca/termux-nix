{ ... }: {
  # urxvt is NOT in the termux repos — it's a custom termux deb built from
  # termux-pkgs/rxvt-unicode/build.sh (see header there for rebuild/install).
  #
  # urxvt reads ~/.Xdefaults directly at startup: nothing in this setup runs
  # xrdb, so the X server has no RESOURCE_MANAGER property and this file is
  # re-read on every launch — config changes apply right after a switch.
  # Colors + font mirror lxterminal.nix / gnome-terminal.nix.
  home.file.".Xdefaults".text = ''
    ! NanumGothicCoding: hangul fallback (pkgs/fonts.nix), dual-width mono
    URxvt.font: xft:IosevkaTermSlab Nerd Font Mono:size=14,xft:NanumGothicCoding:size=14
    ! only ext we load: resize-font (vendored in the deb); steps every size=
    ! in the font list, so latin + hangul scale together. An UNSET
    ! perl-ext-common would load urxvt's "default" ext set — keep it pinned.
    URxvt.perl-ext-common: resize-font
    ! bind as keysym ACTIONS, not URxvt.resize-font.* resources — the ext's
    ! on_init auto-bind silently has no effect on 9.26 (verified on device)
    URxvt.keysym.C-minus: resize-font:smaller
    URxvt.keysym.C-equal: resize-font:bigger
    URxvt.keysym.C-0: resize-font:reset
    URxvt.scrollBar: false
    ! scrollback lives in tmux (mirrors lxterminal scrollback=0)
    URxvt.saveLines: 0
    URxvt.cursorBlink: false
    ! ctrl+shift alone pops the ISO 14755 unicode-entry overlay — disable
    URxvt.iso14755: false
    URxvt.iso14755_52: false
    ! clipboard: builtin ctrl+alt+c / ctrl+alt+v (no clipboard ext loaded)
    URxvt.background: #000000
    URxvt.foreground: #F1FCF8
    URxvt.color0: #3B3B3B
    URxvt.color1: #E05561
    URxvt.color2: #8CC265
    URxvt.color3: #E5C07B
    URxvt.color4: #4AA5F0
    URxvt.color5: #C162DE
    URxvt.color6: #42B3C2
    URxvt.color7: #D7DAE0
    URxvt.color8: #5C6370
    URxvt.color9: #FF616E
    URxvt.color10: #A5E075
    URxvt.color11: #F0C674
    URxvt.color12: #4DC4FF
    URxvt.color13: #DE73FF
    URxvt.color14: #4CD1E0
    URxvt.color15: #FFFFFF
  '';
}
