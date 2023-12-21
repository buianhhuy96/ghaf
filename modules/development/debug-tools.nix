# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ghaf.development.debug.tools;
in
  with lib; {
    config = mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        vim
        bridge-utils
        sshpass
        tcpdump
        gpsd
        networkmanagerapplet
      ];
    };
  }
