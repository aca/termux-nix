{
  home.file.".bashrc".text = ''
    # managed by termux-nix (home-manager); do not edit on device
    alias ll='ls -la'
    export GHQ_ROOT="$HOME/src"
    export GOPATH="$HOME"
    export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
  '';
}
