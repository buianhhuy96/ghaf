# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  weston = config.ghaf.graphics.weston;
  sway = config.ghaf.graphics.sway;
in {
  config = {
    fonts.fonts = with pkgs; 
    lib.lists.optionals  weston.enable [
      fira-code
      hack-font
    ]
    ++ lib.lists.optionals sway.enable [
      font-awesome_5
      font-awesome
    ];
  };
}
