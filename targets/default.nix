# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# List of target configurations
{
  self,
  lib,
  ghafOS,
  nixpkgs,
  nixos-generators,
  nixos-hardware,
  microvm,
  jetpack-nixos,
}:
lib.foldr lib.recursiveUpdate {} [
  (import ./nvidia-jetson-orin.nix {inherit self lib nixpkgs nixos-generators microvm jetpack-nixos;})
  (import ./vm.nix {inherit self lib nixos-generators microvm;})
  (import ./generic-x86_64.nix {inherit self lib nixos-generators nixos-hardware microvm;})
  (import ./imx8qm-mek.nix {inherit self lib nixos-generators nixos-hardware microvm;})
  (import ./installer.nix {inherit self nixpkgs lib ghafOS nixos-generators;})
  (import ./dell-latitude-7330-laptop.nix {inherit self lib ghafOS nixos-generators nixos-hardware microvm;})
  (import ./dell-latitude-7230-tablet.nix {inherit self lib ghafOS nixos-generators nixos-hardware microvm;})
  (import ./dell-latitude-dev.nix {inherit self lib nixos-generators nixos-hardware microvm;})
]
