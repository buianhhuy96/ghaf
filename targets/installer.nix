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
  installer = {name}: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {inherit system;};

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib;};
      modules =
        [
          ../modules/host
          
            
          ({modulesPath, lib, config,...}: {
            imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

            nixpkgs.hostPlatform.system = system;
            nixpkgs.config.allowUnfree = true;

            hardware.enableAllFirmware = true;

            services.avahi.enable = true;
            services.avahi.nssmdns = true;

            ghaf = {
              profiles.installer.enable = true;
              #profiles.applications.enable = true;
            };
            environment.noXlibs = false;
            # For WLAN firmwares
            hardware.enableRedistributableFirmware = true;

            networking = 
            {
              wireless.enable = lib.mkForce false;
              networkmanager.enable = true;
            };

           
          })
          {
            installer.installerScript = {
              enable = true;
              runOnBoot = true;
              # TODO: here we need to choose debug/rel version according to variant
              systems = [
                { name  = "dell-latitude-7330-laptop-debug"; image = self.nixosConfigurations.dell-latitude-7330-laptop-debug; }
                { name  = "dell-latitude-7230-tablet-debug"; image = self.nixosConfigurations.dell-latitude-7230-tablet-debug; }
                ];
            };
          }

          formatModule
          {
            isoImage.squashfsCompression = "lz4"; 
          }
        ]
        ++ (import ../modules/fmo-module-list.nix)
        ++ (import ../modules/module-list.nix) ;
    };
  in {
    name = "${name}-installer";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
  targets = map installer [{name = "general"; }];
in {
  packages = lib.foldr lib.recursiveUpdate {} (map ({name, system, installerImgDrv, ...}: {
    ${system}.${name} = installerImgDrv;
  }) targets);
}
