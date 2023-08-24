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
  formatModule = nixos-generators.nixosModules.raw-efi;
  installer = {name, systemImgCfg}: let
    system = systemImgCfg.config.nixpkgs.hostPlatform.system;

    pkgs = import nixpkgs {inherit system;};
    systemImgDrv = systemImgCfg.config.system.build.${systemImgCfg.config.formatAttr};

    installerScript = import ../modules/installer/installer.nix { inherit pkgs; systemImgDrv = "${systemImgDrv}/nixos.img";  inherit (pkgs) runtimeShell; };

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib;};
      modules =
        [
          ../modules/host
          {
            ghaf = {
              hardware.x86_64.common.enable = true;
              profiles.installer.enable = true;
            };
          }

          {
            # TODO
            environment.loginShellInit = ''
              ${installerScript}/bin/ghaf-installer
            '';
          }

          formatModule
        ]
        ++ (import ../modules/module-list.nix);
    };
  in {
    name = "${name}-installer";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
  targets = map installer [{name = "generic-x86_64-release"; systemImgCfg = self.nixosConfigurations.generic-x86_64-release;}];
in {
  packages = lib.foldr lib.recursiveUpdate {} (map ({name, system, installerImgDrv, ...}: {
    ${system}.${name} = installerImgDrv;
  }) targets);
}
