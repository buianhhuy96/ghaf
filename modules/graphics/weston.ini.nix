# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.demo-apps;
  weston = config.ghaf.graphics.weston;

in 
{  
  config.ghaf.graphics =  {
    demo-apps = with lib; mkForce {
      chromium        = true;
      firefox         = false;
      gala-app        = false;
      element-desktop = false;
      zathura         = false;
    };
    weston.launchers = 
      lib.mkForce [
      {
        path = "${pkgs.weston}/bin/weston-terminal";
        icon = "${pkgs.weston}/share/weston/icon_terminal.png";
      }
      {
        path = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland 192.168.101.11";
        icon = "${pkgs.chromium}/share/icons/hicolor/24x24/apps/chromium.png";
      }
  
      ];
  };
}