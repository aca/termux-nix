# Font packages to expose to termux natively. Each package's share/fonts is
# linked under ~/.local/share/fonts/<pname>, which termux fontconfig scans
# recursively (through the symlink into the container store). Fonts are
# plain data, so no proot/libc concern — but the WHOLE package rides the
# pushed closure; mind the size when adding.
{
  pkgs,
  lib,
  ...
}:
let
  fonts = [
    (pkgs.runCommand "iosevka-term-slab-nf-mono" { } ''
      mkdir -p $out/share/fonts
      cp ${pkgs.nerd-fonts.iosevka-term-slab}/share/fonts/truetype/NerdFonts/IosevkaTermSlab/IosevkaTermSlabNerdFontMono-*.ttf $out/share/fonts/
    '')

    (pkgs.runCommand "aporetic-serif-mono" { } ''
      mkdir -p $out/share/fonts
      cp ${pkgs.aporetic-bin}/share/fonts/truetype/aporetic-serif-mono/TTF/*.ttf $out/share/fonts/
    '')

    (pkgs.runCommand "ibm-plex-kr" { } ''
      mkdir -p $out/share/fonts
      cp ${pkgs.ibm-plex}/share/fonts/truetype/*KR*.ttf $out/share/fonts/
    '')

    # hangul in urxvt (fallback in URxvt.font, pkgs/rxvt-unicode.nix);
    # dual-width monospaced hangul, made for terminals/editors
    (pkgs.runCommand "nanum-gothic-coding" { } ''
      mkdir -p $out/share/fonts
      cp ${pkgs.nanum-gothic-coding}/share/fonts/NanumGothicCoding/*.ttf $out/share/fonts/
    '')
  ];
in
{
  xdg.dataFile = lib.listToAttrs (
    map (f: {
      name = "fonts/${f.pname or f.name}";
      value.source = "${f}/share/fonts";
    }) fonts
  );
}
