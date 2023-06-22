# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  microvm,
  system,
}:
lib.nixosSystem {
  inherit system;
  specialArgs = {inherit lib;};
  modules = [
    # TODO: Enable only for development builds
    ../../modules/users/accounts.nix
    {
      ghaf.users.accounts.enable = true;
    }
    ../../modules/development/ssh.nix
    {
      ghaf.development.ssh.daemon.enable = true;
    }
    ../../modules/development/debug-tools.nix
    {
      ghaf.development.debug.tools.enable = true;
    }

    microvm.nixosModules.microvm

    ({
      pkgs,
      lib,
      ...
    }: {
      networking.hostName = "netvm";
      # TODO: Maybe inherit state version
      system.stateVersion = lib.trivial.release;

      # TODO: crosvm PCI passthrough does not currently work
      microvm.hypervisor = "qemu";

      networking = {
        enableIPv6 = false;
        interfaces.ethint0.useDHCP = false;
        firewall.allowedTCPPorts = [22];
        firewall.allowedUDPPorts = [67];
        useNetworkd = true;
      };

      microvm.interfaces = [
        {
          type = "tap";
          id = "vm-netvm";
          mac = "02:00:00:01:01:01";
        }
      ];

      networking.nat = {
        enable = true;
        internalInterfaces = ["ethint0"];
      };

      # Set internal network's interface name to ethint0
      systemd.network.links."10-ethint0" = {
        matchConfig.PermanentMACAddress = "02:00:00:01:01:01";
        linkConfig.Name = "ethint0";
      };

      systemd.network = {
        enable = true;
        networks."10-ethint0" = {
          matchConfig.MACAddress = "02:00:00:01:01:01";
          networkConfig.DHCPServer = true;
          dhcpServerConfig.ServerAddress = "192.168.100.1/24";
          addresses = [
            {
              addressConfig.Address = "192.168.100.1/24";
            }
            {
              # IP-address for debugging subnet
              addressConfig.Address = "192.168.101.1/24";
            }
          ];
          linkConfig.ActivationPolicy = "always-up";
        };
      };

      microvm.qemu.bios.enable = false;
    })
  ];
}
