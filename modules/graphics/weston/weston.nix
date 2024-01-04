# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.weston;
  weston-12 = pkgs.callPackage ./weston-12/weston-12.0.2.nix {};
in {
  options.ghaf.graphics.weston = {
    enable = lib.mkEnableOption "weston";
  };

  config = lib.mkIf cfg.enable {

    ghaf.graphics.window-manager-common.enable = true;

    environment.systemPackages = with pkgs; [
      weston-12
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
      wantedBy = ["weston.service"];
    };

    # Weston service
    systemd.user.services."weston" = {
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
        ExecStart = "${weston-12}/bin/weston";
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
      wantedBy = ["default.target"];
    };
  };
}
