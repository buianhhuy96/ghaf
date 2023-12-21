# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}: let
  cfg = config.ghaf.profiles.applications;
in
  with lib; {
    config = mkIf cfg.enable {
      #TODO Should we assert dependency on graphics (weston) profile?
      #For now enable weston + apps
      ghaf.graphics.weston = {
        enable = mkForce false;
        enableDemoApplications = mkForce false;
      };
      ghaf.graphics.weston-12 = {
        enable = true;
        enableDemoApplications = true;
      };
    };
  }
