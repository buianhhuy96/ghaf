# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
  # TO-BE-REMOVED
  # This is only use as example
  example-app = pkgs.callPackage ../registration-agent/registration-agent-laptop.nix {inherit pkgs; };
  example-file = ./.env;
in   
{
  config.services.file-list = {
    # TO-USE
    # 1. Set enable = true;
    # 2. enableFiles = [ "<name of the folder, if src is fetched link>"  ]
    # 3. create a set
    #   file-info.<name-in-enableFiles> =
    #        { src-path = <local-file or git>; 
    #          des-path = <destination-to-copy-to>;
    #          permission = <file permission>; }
    # 4. git add <local-file> 
    enable = false;
    enabledFiles = [ "registration-agent" ];
    file-info = {
      registration-agent = { 
        src-path = example-app;
        des-path = "${config.users.users.ghaf.home}";
        permission = "774";
      };
    };
  };
}