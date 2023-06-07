# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # For lspci:
    pciutils

    # For lsusb:
    usbutils

    # Useful in NetVM
    ethtool

    # Wireless tools
    wirelesstools

    # Human-friendly editors
    vim

    # Docker
    docker-compose

    # Basic monitors
    htop
    iftop
    iotop

    traceroute
    dig
  ];
}
