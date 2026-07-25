{ ... }: {
  xdg.configFile."konsolerc".text = ''
    MenuBar=Disabled

    [Desktop Entry]
    DefaultProfile=termux-nix.profile

    [General]
    ConfigVersion=1

    [MainWindow]
    MenuBar=Disabled
    ToolBarsMovable=Enabled

    [SplitView]
    SplitDragHandleSize=SplitDragHandleLarge
    SplitViewVisibility=AlwaysHideSplitHeader

    [TabBar]
    TabBarVisibility=AlwaysHideTabBar

    [UiSettings]
    ColorScheme=
  '';

  # konsole >= 22.04 reads window state (incl. toolbar visibility) from
  # konsolestaterc, not konsolerc — Hidden= entries there are ignored.
  xdg.configFile."konsolestaterc".text = ''
    [MainWindow][Toolbar mainToolBar]
    Hidden=true

    [MainWindow][Toolbar sessionToolbar]
    Hidden=true
  '';

  xdg.dataFile."konsole/termux-nix.profile".text = ''
    [Appearance]
    ColorScheme=termux-nix
    Font=IosevkaTermSlab NFM,12,-1,5,50,0,0,0,0,0

    [General]
    Name=termux-nix
    Parent=FALLBACK/
    SemanticHints=0
    AlternatingBackground=0
    AlternatingBars=0
    ErrorBackground=0
    ErrorBars=0

    [Scrolling]
    ScrollBarPosition=2
  '';

  xdg.dataFile."konsole/termux-nix.colorscheme".text = ''
    [General]
    Description=termux-nix
    Opacity=1

    [Background]
    Color=0,0,0

    [BackgroundIntense]
    Color=0,0,0

    [Foreground]
    Color=241,252,248

    [ForegroundIntense]
    Color=241,252,248

    [Color0]
    Color=59,59,59

    [Color0Intense]
    Color=92,99,112

    [Color1]
    Color=224,85,97

    [Color1Intense]
    Color=255,97,110

    [Color2]
    Color=140,194,101

    [Color2Intense]
    Color=165,224,117

    [Color3]
    Color=229,192,123

    [Color3Intense]
    Color=240,198,116

    [Color4]
    Color=74,165,240

    [Color4Intense]
    Color=77,196,255

    [Color5]
    Color=193,98,222

    [Color5Intense]
    Color=222,115,255

    [Color6]
    Color=66,179,194

    [Color6Intense]
    Color=76,209,224

    [Color7]
    Color=215,218,224

    [Color7Intense]
    Color=255,255,255
  '';
}
