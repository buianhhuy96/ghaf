# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs, systemImgDrv}:
pkgs.buildGo120Module {
  name = "pterm";
  src = ./src;
  vendorSha256 = "sha256-okh66bWoTUrX13b+hu9bgQNyrmFk+Io2hUjQYEJwwD8="; #"sha256-37pfoPAa6BlezFu6eDOL7+Vp6HFB1gk/rCNnA85YxxY=";
  proxyVendor=true;

  ldflags = [
    "-X main.ghaf=${systemImgDrv}"
  ];

    # ...
}
