# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Generic x86_64 (for now) computer installer
{
  self,
  nixpkgs,
  nixos-generators,
  lib,
}: let
  formatModule = nixos-generators.nixosModules.iso;
  installer = {name, systemImgCfg}: let
    system = systemImgCfg.config.nixpkgs.hostPlatform.system;

    pkgs = import nixpkgs {inherit system;};
    systemImgDrv = systemImgCfg.config.system.build.${systemImgCfg.config.formatAttr};

    
    installModule = (import ../modules/installer/installer-graphic.nix { inherit pkgs; inherit lib;  systemImgDrv = "${systemImgDrv}";});
    #import ../modules/installer/installer.nix { inherit pkgs; systemImgDrv = "${systemImgDrv}/nixos.img";  inherit (pkgs) runtimeShell; };

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib;};
      modules =
        [
          ../modules/host        
            
          ({modulesPath, lib, ...}: {
            imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

            nixpkgs.hostPlatform.system = system;
            nixpkgs.config.allowUnfree = true;

            hardware.enableAllFirmware = true;

            ghaf = {
              profiles.installer.enable = true;
              profiles.applications.enable = true;
            };
            # For WLAN firmwares
            hardware.enableRedistributableFirmware = true;

            networking = 
            {
              wireless.enable = lib.mkForce false;
              networkmanager.enable = true;
            };
            
            isoImage.squashfsCompression = "lz4";  
            

          })

          
          installModule
          formatModule
        ]
        ++ (import ../modules/module-list.nix) ;
    };
  in {
    name = "${name}-installer";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
  targets = map installer [{name = "generic-x86_64-debug"; systemImgCfg = self.nixosConfigurations.generic-x86_64-debug;}];
in {
  packages = lib.foldr lib.recursiveUpdate {} (map ({name, system, installerImgDrv, ...}: {
    ${system}.${name} = installerImgDrv;
  }) targets);
}