# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs, lib, systemImgDrv, ...}:
let
  installerScript = pkgs.callPackage ./calamares  {  };
  installerScript2 = pkgs.callPackage ./calamares/extension  {  };
in
{
  

  environment.noXlibs = false;
  
  environment.systemPackages = with pkgs; [
    libsForQt5.kpmcore
    calamares-nixos
    installerScript2
    # Get list of locales
    glibcLocales
    ];  

  environment.variables = {
    QT_QPA_PLATFORM = "wayland";
  };

  # Support choosing from any locale
  i18n.supportedLocales = [ "all" ];
  #services.xserver = {
  #  enable = true;
  #  # Automatically login as nixos.
  #  displayManager = {
  #    startx.enable = true;
  #    autoLogin = {
  #      enable = true;
  #      user = "ghaf";
  #    };
  #  };
#
  #  };
  #hardware.nvidia.package = boot.kernelPackages.nvidiaPackages.stable;
  hardware.opengl = {
    enable = true;
    driSupport=true;
  };

}