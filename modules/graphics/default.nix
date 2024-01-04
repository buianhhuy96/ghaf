# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}:{
  imports = [
    ./demo-apps.nix
    ./weston/weston.nix
    ./weston/weston.ini.nix
    ./sway/sway.nix
    ./sway/sway.ini.nix
    ./fonts.nix
    ./window-manager.nix
  ];
  
}
