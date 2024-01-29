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

    #environment.etc."sway/config" = {
    #  source = ./config;
    #  # The UNIX file mode bits
    #  mode = "0666";
    #};

    
    services.file-list = {
      enable = true;
      enabledFiles = [ "config-folder" "sway-config" ];
      file-info = {
        config-folder = { 
          des-path = "${config.users.users.ghaf.home}/.config";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
        };
        sway-config = { 
          src-path = ./configFile;
          des-path = "${config.users.users.ghaf.home}/.config/sway";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
          permission = "777";
        };
      };
    };

  };
}
