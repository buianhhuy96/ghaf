# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# List of modules
{
  imports = [
    ./boot/systemd-boot-dtb.nix
    ./hardware/nvidia-jetson-orin
    ./hardware/x86_64-linux.nix
    ./graphics
    ./host
    ./version
    ./windows-launcher
  ];
}
