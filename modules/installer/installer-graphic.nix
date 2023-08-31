# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs, lib, systemImgDrv, ...}:
let
  installerScript = pkgs.callPackage ./fyne  { inherit pkgs; systemImgDrv = "/etc/nixos.img";  };
in
{
  isoImage.edition = "plasma5";
  isoImage.squashfsCompression = "lz4";          

  environment.noXlibs = false;
  
  environment.systemPackages = [installerScript];  
  environment.etc."nixos.img" = {
              source = "${systemImgDrv}/nixos.img"; 
            };

  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
    # Automatically login as nixos.
    displayManager = {
      sddm.enable = true;
      autoLogin = {
        enable = true;
        user = "ghaf";
      };
 };

    };
  #hardware.nvidia.package = boot.kernelPackages.nvidiaPackages.stable;
  hardware.opengl = {
    enable = true;
    driSupport=true;
  };

}