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

#      microvm.hypervisor = "crosvm";
      microvm.hypervisor = "qemu";

      networking = {
        enableIPv6 = false;
        firewall.allowedTCPPorts = [22];
        useNetworkd = true;
      };

      systemd.network.enable = true;

      microvm.interfaces = [
        {
          type = "tap";
          id = "vm-appvm-elinks";
          mac = "02:00:00:02:03:04";
        }
      ];

      environment.systemPackages = with pkgs; [
        elinks
      ];

      microvm.qemu.bios.enable = false;
    })
  ];
}
