{
  xdg.configFile."i3status/config".text = ''
    general {
      output_format = "i3bar"
      colors = true
      interval = 5
    }

    order += "wireless _first_"
    order += "battery all"
    order += "memory"
    order += "tztime local"

    wireless _first_ {
      format_up = "W: %essid"
      format_down = "W: down"
    }

    battery all {
      format = "%status %percentage"
    }

    memory {
      format = "%used/%total"
    }

    tztime local {
      format = "%Y-%m-%d %H:%M"
    }
  '';
}
