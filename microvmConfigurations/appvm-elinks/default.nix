# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  nixpkgs,
  microvm,
  system,
}:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    # TODO: Enable only for development builds
    ../../modules/development/authentication.nix
    ../../modules/development/ssh.nix
    ../../modules/development/packages.nix

    microvm.nixosModules.microvm

    ({pkgs, ...}: {
      networking.hostName = "appvm-elinks";
      # TODO: Maybe inherit state version
      system.stateVersion = "22.11";

      microvm.hypervisor = "kvmtool";

      networking = {
        enableIPv6 = false;
        interfaces.ethint0.useDHCP = false;
        firewall.allowedTCPPorts = [22];
        useNetworkd = true;
      };

#      systemd.network.enable = true;

      microvm.interfaces = [
        {
          type = "tap";
          id = "vm-appvm-elinks";
          mac = "02:00:00:02:03:04";
        }
      ];

      # Set internal network's interface name to ethint0
      systemd.network.links."10-ethint0" = {
        matchConfig.PermanentMACAddress = "02:00:00:02:03:04";
        linkConfig.Name = "ethint0";
      };

      systemd.network = {
        enable = true;
        networks."10-ethint0" = {
          matchConfig.MACAddress = "02:00:00:02:03:04";
          addresses = [
            {
              # IP-address for debugging subnet
              addressConfig.Address = "192.168.101.11/24";
            }
          ];
          routes =  [
            { routeConfig.Gateway = "192.168.101.1"; }
          ];
          linkConfig.RequiredForOnline = "routable";
          linkConfig.ActivationPolicy = "always-up";
        };
      };

      environment.systemPackages = with pkgs; [
        elinks
      ];

      microvm.qemu.bios.enable = false;
    })
  ];
}
