# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  ...
}: let
  cfg = config.ghaf.hardware.x86_64.common;
in
  with lib; {
    config = mkIf cfg.enable {
      # Add NVMe support into initrd to be able to boot from it
      boot.initrd.availableKernelModules = [ "nvme" "ahci" ];

    };
  }
