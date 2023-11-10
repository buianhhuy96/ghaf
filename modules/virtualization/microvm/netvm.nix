# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ghafOS}:{
  config,
  lib,
  ...
}: let
  configHost = config;
in
{
  services.udev.extraRules = ''
    # Add usb to kvm group
    SUBSYSTEM=="net", ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idProduct}=="a4a2", ATTRS{idVendor}=="0525", NAME="mesh0"
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="e1000e", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", NAME="eth0"
  '';

  #microvm.qemu.extraArgs = [
  #  "-usb"
  #  "-device"
  #  "usb-host,vendorid=0x0525,productid=0xa4a2"
  #];

  services =
  {
    portforwarding-service = {
      enable = true;
      ipaddress-path = "/etc/NetworkManager/system-connections/ip-address";
      dip = "192.168.101.11";
      dport = "4222";
      sport = "4222";
    };
  };

  networking.networkmanager = {
    enable=true;
    unmanaged = [
      "ethint0"
    ];
  };

	microvm.shares = lib.mkDefault [
    {
	    # On the host
	    source = "/var/netvm/netconf";
	    # In the MicroVM
	    mountPoint = "/etc/NetworkManager/system-connections";
	    tag = "netconf";
	    proto = "virtiofs";
	    socket = "netconf.sock";
	  }
  ];

  microvm.storeDiskType = "squashfs";

  imports = (import "${ghafOS}/modules/module-list.nix") ++ (import ../../fmo-module-list.nix);
}
    
  