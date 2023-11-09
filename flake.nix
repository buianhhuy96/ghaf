# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "Ghaf - Documentation and implementation for TII SSRC Secure Technologies Ghaf Framework";

  nixConfig = {
    extra-trusted-substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
    ];
    extra-trusted-public-keys = [
      "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
    ];
  };

  inputs = rec {
    ghafOS.url = "github:tiiuae/ghaf";
  };

  outputs = {
    self,
    ghafOS,
  }: let
    # Retrieve inputs from Ghaf
    nixpkgs = ghafOS.inputs.nixpkgs;
    flake-utils = ghafOS.inputs.flake-utils;
    nixos-generators = ghafOS.inputs.nixos-generators;
    nixos-hardware = ghafOS.inputs.nixos-hardware;
    microvm = ghafOS.inputs.microvm;
    jetpack-nixos = ghafOS.inputs.jetpack-nixos;

    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
    lib = nixpkgs.lib.extend (final: _prev: {
      ghaf = import ./lib {
        inherit self;
        lib = final;
      };
    });
  in
    # Combine list of attribute sets together
    lib.foldr lib.recursiveUpdate {} [
      # Documentation
      (flake-utils.lib.eachSystem systems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.doc = pkgs.callPackage ./docs {
          revision = lib.version;
          options = let
            cfg = nixpkgs.lib.nixosSystem {
              inherit system;
              modules =
                lib.ghaf.modules
                ++ [
                  jetpack-nixos.nixosModules.default
                  microvm.nixosModules.host
                ];
            };
          in
            cfg.options;
        };

        formatter = pkgs.alejandra;
      }))

      # ghaf lib
      {
        lib = lib.ghaf;
      }

      # Target configurations
      (import ./targets {inherit self lib ghafOS nixpkgs nixos-generators nixos-hardware microvm jetpack-nixos;})

      # User apps
      (import ./user-apps {inherit lib nixpkgs flake-utils;})

      # Hydra jobs
      (import ./hydrajobs.nix {inherit self;})

      #templates
      (import ./templates)
    ];
}
