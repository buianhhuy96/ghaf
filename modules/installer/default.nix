# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs, systemImgCfg}:
let 
  installerDir = ./src;
  system0 = "${(builtins.elemAt systemImgCfg 0).config.system.build.${(builtins.elemAt systemImgCfg 0).config.formatAttr}}/nixos.img";
  system1 = "${(builtins.elemAt systemImgCfg 1).config.system.build.${(builtins.elemAt systemImgCfg 1).config.formatAttr}}/nixos.img";
  system2 = "${(builtins.elemAt systemImgCfg 2).config.system.build.${(builtins.elemAt systemImgCfg 2).config.formatAttr}}/nixos.img";
  registration-agent-laptop = pkgs.callPackage ../registration-agent/registration-agent-laptop.nix {inherit pkgs; };

in
pkgs.buildGo120Module {
  name = "ghaf-installer";
  src = ./src;
  vendorSha256 = "sha256-MKMsvIP8wMV86dh9Y5CWhgTQD0iRpzxk7+0diHkYBUo=";
  proxyVendor=true;

  # TODO: here we need to choose debug/rel version according to variant
  ldflags = [
    "-X ghaf-installer/global.Images=dell-latitude-7330-laptop-debug||${system0}||dell-latitude-7230-tablet-debug||${system1}||dell-latitude-dev-debug||${system2}"
    "-X ghaf-installer/screen.screenDir=${installerDir}/screen"
    "-X ghaf-installer/screen.registrationAgentScript=${registration-agent-laptop}/bin/registration-agent-laptop-orig"
    
  ];

    # ...
}
