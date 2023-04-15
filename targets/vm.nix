# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  nixpkgs,
  nixos-generators,
  microvm,
}: let
  name = "vm";
  system = "x86_64-linux";
  formatModule = nixos-generators.nixosModules.vm;
  vm = variant: let
    hostConfiguration = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        (import ../modules/host {
          inherit self microvm netvm firefoxvm;
        })

        ../modules/hardware/x86_64-linux.nix

        ./common-${variant}.nix

        ../modules/graphics/weston.nix

        formatModule
      ];
    };
    netvm = "netvm-${name}-${variant}";
    firefoxvm = "appvm-firefox-${name}-${variant}";
  in {
    inherit hostConfiguration netvm firefoxvm;
    name = "${name}-${variant}";
    # TODO: Define some passthrough for NetVM
    netvmConfiguration = import ../microvmConfigurations/netvm {
      inherit nixpkgs microvm system;
    };
    firefoxvmConfiguration = import ../microvmConfigurations/appvm-firefox {
      inherit nixpkgs microvm system;
    };
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  targets = [
    (vm "debug")
    (vm "release")
  ];
in {
  nixosConfigurations =
    builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.name t.hostConfiguration) targets)
    // builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.netvm t.netvmConfiguration) targets)
    // builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.firefoxvm t.firefoxvmConfiguration) targets);
  packages = {
    x86_64-linux =
      builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.name t.package) targets);
  };
}
