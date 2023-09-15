# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs, systemImgDrv}:
let 
#fyne = pkgs.callPackage ./fyne.nix {};

in
pkgs.buildGo120Module {
  name = "fyne";
  src = ./src;
  vendorSha256 = "sha256-P3L4fgESnvCIe0NWMRGP1G35cD735LJun+aWJsrf6GU=";
  proxyVendor=true;

  ldflags = [
    "-X ghaf-fyne/tutorials.ghaf=${systemImgDrv}"
  ];
  
  tags = [ "wayland" ];
  nativeBuildInputs = [pkgs.pkg-config];
  
  buildInputs = with pkgs; #[xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXinerama xorg.libXi libGLU xorg.libXxf86vm] ;
    [wayland wayland-protocols libxkbcommon extra-cmake-modules libGL
    xorg.libX11];
  excludedPackages = ["./fyne_settings/settings"];
}
