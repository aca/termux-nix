{ lib, ... }:
let
in
{
  home.file = {
    ".local/bin/pbpaste" = {
      text = ''
        #!/data/data/com.termux/files/usr/bin/bash
        exec xsel --clipboard --output
      '';
      executable = true;
    };

    ".local/bin/co" = {
      text = ''
        #!/data/data/com.termux/files/usr/bin/bash
        exec xsel --clipboard --output
      '';
      executable = true;
    };

    ".local/bin/pbcopy" = {
      text = ''
        #!/data/data/com.termux/files/usr/bin/bash
        exec xsel --clipboard --input
      '';
      executable = true;
    };

    ".local/bin/ci" = {
      text = ''
        #!/data/data/com.termux/files/usr/bin/bash
        exec xsel --clipboard --input
      '';
      executable = true;
    };
  };
}
