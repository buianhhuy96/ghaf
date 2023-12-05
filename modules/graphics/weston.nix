# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.weston;
  weston-12= pkgs.callPackage ./weston-12/weston-12.0.2.nix {};
in {
  options.ghaf.graphics.weston = {
    enable = lib.mkEnableOption "weston";
  };

  config = lib.mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport = true;
    };

    environment.noXlibs = false;
    environment.systemPackages = with pkgs; [
      weston-12
      # Seatd is needed to manage log-in process for weston
      seatd
    ];

    # Next 4 services/targets are taken from official weston documentation:
    # https://wayland.pages.freedesktop.org/weston/toc/running-weston.html
    #
    # To run weston, after log-in to VT or SSH run:
    # systemctl --user start weston.service
    #
    # I am pretty sure it is possible to have it running automatically, I just
    # haven't found the way yet.

    # Weston socket
    systemd.user.sockets."weston" = {
      unitConfig = {
        Description = "Weston, a Wayland compositor";
        Documentation = "man:weston(1) man:weston.ini(5)";
      };
      socketConfig = {
        ListenStream = "%t/wayland-0";
      };
      wantedBy = ["weston-edp.service" "weston-external.service"];
    };

    # Service to decide which version of config should be ran
    # If there are more 1 screens connected, use weston-external.service
    # If there is only 1 screen connected, use weston-edp.service 
    systemd.user.services."weston" = {
      enable = true;
      requires = ["weston.socket"];
      after = ["weston.socket" "ghaf-session.service"];
      script = ''
        PRE_STATUS="1"
        ${pkgs.systemd}/bin/systemctl --user start weston-edp.service
        while true; do
          ${pkgs.coreutils}/bin/sleep 1
          STATUS=$(${pkgs.coreutils}/bin/cat /sys/class/drm/*/status | grep -wc "connected")
          if [[ "$STATUS" != "$PRE_STATUS" ]]; then
            if [[ "$STATUS" == "2" ]]; then
              ${pkgs.systemd}/bin/systemctl --user stop weston-edp.service
              ${pkgs.systemd}/bin/systemctl --user start weston-external.service
            else
              ${pkgs.systemd}/bin/systemctl --user stop weston-external.service
              ${pkgs.systemd}/bin/systemctl --user start weston-edp.service
            fi
            PRE_STATUS=$STATUS
          fi

        done
      '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5";
      };
      wantedBy = ["default.target"];
    };
    
    # Weston service
    systemd.user.services."weston-edp" = {
      enable = true;
      description = "Weston, a Wayland compositor, as a user service TEST";
      documentation = ["man:weston(1) man:weston.ini(5)" "https://wayland.freedesktop.org/"];
      requires = ["weston.socket"];
      after = ["weston.socket" "ghaf-session.service"];
      serviceConfig = {
        # Previously there was "notify" type, but for some reason
        # systemd kills weston.service because of timeout (even if it is disabled).
        # "simple" works pretty well, so let's leave it.
        Type = "simple";
        #TimeoutStartSec = "60";
        #WatchdogSec = "20";
        # Defaults to journal
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = "${weston-12}/bin/weston --config=/etc/xdg/weston/weston-edp.ini";
        # Ivan N: I do not know if this is bug or feature of NixOS, but
        # when I add weston.ini file to environment.etc, the file ends up in
        # /etc/xdg directory on the filesystem, while NixOS uses
        # /run/current-system/sw/etc/xdg directory and goes into same directory
        # searching for weston.ini even if /etc/xdg is already in XDG_CONFIG_DIRS
        # The solution is to add /etc/xdg one more time for weston service.
        # It does not affect on system-wide XDG_CONFIG_DIRS variable.
        Environment = "XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS:/etc/xdg";

        Restart = "always";
        RestartSec = "5";
      };
      #wantedBy = ["default.target"];
    };

    systemd.user.services."weston-external" = {
      enable = true;
      description = "Weston, a Wayland compositor, as a user service TEST";
      documentation = ["man:weston(1) man:weston.ini(5)" "https://wayland.freedesktop.org/"];
      requires = ["weston.socket"];
      after = ["weston.socket" "ghaf-session.service"];
      serviceConfig = {
        # Previously there was "notify" type, but for some reason
        # systemd kills weston.service because of timeout (even if it is disabled).
        # "simple" works pretty well, so let's leave it.
        Type = "simple";
        #TimeoutStartSec = "60";
        #WatchdogSec = "20";
        # Defaults to journal
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = "${weston-12}/bin/weston --config=/etc/xdg/weston/weston-external.ini";
        # Ivan N: I do not know if this is bug or feature of NixOS, but
        # when I add weston.ini file to environment.etc, the file ends up in
        # /etc/xdg directory on the filesystem, while NixOS uses
        # /run/current-system/sw/etc/xdg directory and goes into same directory
        # searching for weston.ini even if /etc/xdg is already in XDG_CONFIG_DIRS
        # The solution is to add /etc/xdg one more time for weston service.
        # It does not affect on system-wide XDG_CONFIG_DIRS variable.
        Environment = "XDG_CONFIG_DIRS=$XDG_CONFIG_DIRS:/etc/xdg";

        Restart = "always";
        RestartSec = "5";
      };
      #wantedBy = ["default.target"];
    };

    systemd.user.targets."ghaf-session" = {
      description = "Ghaf graphical session";
      bindsTo = ["ghaf-session.target"];
      before = ["ghaf-session.target"];
    };

    systemd.services."ghaf-session" = {
      description = "Ghaf graphical session";

      # Make sure we are started after logins are permitted.
      after = ["systemd-user-sessions.service"];

      # if you want you can make it part of the graphical session
      #Before=graphical.target

      # not necessary but just in case
      #ConditionPathExists=/dev/tty7

      serviceConfig = {
        Type = "simple";
        Environment = "XDG_SESSION_TYPE=wayland";
        ExecStart = "${pkgs.systemd}/bin/systemctl --wait --user start ghaf-session.target";

        # The user to run the session as. Pick one!
        User = config.ghaf.users.accounts.user;
        Group = config.ghaf.users.accounts.user;

        # Set up a full user session for the user, required by Weston.
        PAMName = "${pkgs.shadow}/bin/login";

        # A virtual terminal is needed.
        TTYPath = "/dev/tty7";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "yes";

        # Try to grab tty .
        StandardInput = "tty-force";

        # Defaults to journal, in case it doesn't adjust it accordingly
        #StandardOutput=journal
        StandardError = "journal";

        # Log this user with utmp, letting it show up with commands 'w' and 'who'.
        UtmpIdentifier = "tty7";
        UtmpMode = "user";

        Restart = "always";
        RestartSec = "5";
      };
      wantedBy = ["multi-user.target"];
    };

    # systemd service for seatd
    systemd.services."seatd" = {
      description = "Seat management daemon";
      documentation = ["man:seatd(1)"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.seatd}/bin/seatd -g video";
        Restart = "always";
        RestartSec = "1";
      };
      wantedBy = ["multi-user.target"];
    };
  };
}
