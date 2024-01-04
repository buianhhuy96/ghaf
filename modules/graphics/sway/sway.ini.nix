# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.sway;
 
in {
  imports = [
    ./nwg-panel/nwg-panel.nix
  ];
  
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        brightnessctl
        nwg-dock
        nwg-drawer
        nwg-wrapper
        #nwg-displays
        
        nwg-bar
        nwg-menu
      ];

    # normal weston config
    environment.etc."sway/config" = {
      source = ./config;
      # The UNIX file mode bits
      mode = "0644";
    };
  };
}
