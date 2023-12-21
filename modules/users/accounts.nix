# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  options,
  ...
}:
# account for the development time login with sudo rights
let
  cfg = config.ghaf.users.accounts;
in
  with lib; {
    config = mkIf cfg.enable {
      users = {
        mutableUsers = true;
        users."${cfg.user}" = {
          isNormalUser = true;
          password = cfg.password;
          #TODO add "docker" use "lib.optionals"
          extraGroups = ["wheel" "video" "docker" "dialout" "networkmanager"];
        };
        groups."${cfg.user}" = {
          name = cfg.user;
          members = [cfg.user];
        };
      };
    };
  }
