{ config, pkgs, ... }:
let
  directions = {
    h = "l";
    j = "d";
    k = "u";
    l = "r";
    left = "l";
    down = "d";
    up = "u";
    right = "r";
  };
in
{
  xdg.configFile."uwsm/env".text = ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
  '';
  home.packages = with pkgs; [
    wofi
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    polkit_gnome
    ranger
    libnotify
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    systemd.enable = false;
    settings = {
      "$mod" = "SUPER";
      monitor = [ ",preferred,auto,1.5" ];
      general = {
        border_size = 1;
        layout = "dwindle";
      };
      decoration = {
        rounding = 6;
        active_opacity = 1.0;
        inactive_opacity = 0.9;
        blur = {
          enabled = true;
          size = 3;
          passes = 3;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
        };
      };
      animations.enabled = false;
      input = {
        kb_layout = "us";
        follow_mouse = 0;
        repeat_rate = 40;
        repeat_delay = 600;
        natural_scroll = true;
        touchpad.natural_scroll = true;
      };
      dwindle = {
        preserve_split = true;
        force_split = 2;
      };
      misc.disable_hyprland_logo = true;
      exec-once = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"
      ];
      bind = [
        "$mod, Return, exec, uwsm app -- ghostty"
        "$mod SHIFT, Return, exec, uwsm app -- firefox"
        "$mod, Q, killactive,"
        "$mod, E, exec, uwsm app -- ghostty -e ranger"
        "$mod, V, togglefloating,"
        "$mod, Space, exec, wofi --show drun"
        "$mod, Tab, workspace, previous"
        "$mod, Escape, exec, loginctl lock-session"
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
      ]
      ++ builtins.concatLists (
        builtins.attrValues (
          builtins.mapAttrs (key: direction: [
            "$mod, ${key}, movefocus, ${direction}"
            "$mod SHIFT, ${key}, movewindow, ${direction}"
          ]) directions
        )
      )
      ++ builtins.concatLists (
        builtins.genList (
          index:
          let
            workspace = toString (index + 1);
            key = if index == 9 then "0" else workspace;
          in
          [
            "$mod, ${key}, workspace, ${workspace}"
            "$mod SHIFT, ${key}, movetoworkspacesilent, ${workspace}"
          ]
        ) 10
      );
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
      bindl = [ ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" ];
    };
  };
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [
        "pulseaudio"
        "network"
        "battery"
        "tray"
      ];
    };
  };
  services.mako.enable = true;
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = "${../wallpapers/a-chosen-soul.jpg}";
          fit_mode = "cover";
        }
      ];
    };
  };
  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      background = [
        {
          path = "${../wallpapers/a-chosen-soul.jpg}";
          blur_passes = 3;
        }
      ];
      input-field = [
        {
          size = "300, 60";
          position = "0, -80";
          monitor = "";
        }
      ];
    };
  };
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
