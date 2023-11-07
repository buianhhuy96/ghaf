# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Generic x86_64 computer -target
{
  self,
  lib,
  ghafOS,
  nixos-generators,
  nixos-hardware,
  microvm,
}: let
  name = "dell-latitude-7330-laptop";
  system = "x86_64-linux";
  formatModule = nixos-generators.nixosModules.raw-efi;
  dell-7330-x86 = variant: extraModules: let
    netvmExtraModules = [
      {
        microvm.devices = [
          {
            bus = "pci";
            path = "0000:72:00.0";
          }

          {
            bus = "pci";
            path = "0000:00:1f.0";
          }
          {
            bus = "pci";
            path = "0000:00:1f.3";
          }
          {
            bus = "pci";
            path = "0000:00:1f.4";
          }
          {
            bus = "pci";
            path = "0000:00:1f.5";
          }
          {
            bus = "pci";
            path = "0000:00:1f.6";
          }
        ];

        # For WLAN firmwares
        hardware.enableRedistributableFirmware = true;

        networking.wireless = {
          enable = true;

          # networks."SSID_OF_NETWORK".psk = "WPA_PASSWORD";
        };
      }
    ];
    hostConfiguration = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          microvm.nixosModules.host
          (ghafOS + /modules/host)
          (ghafOS + /modules/virtualization/microvm/microvm-host.nix)
          ../modules/virtualization/microvm/netvm.nix
          ../modules/virtualization/microvm/dockervm.nix
          {
            services = {
              registration-agent = {
                enable = true;
                env-path= "/home/ghaf";
              };
            };

            services.udev.extraRules = ''
              # Add usb to kvm group
              SUBSYSTEM=="usb", ATTR{idVendor}=="0525", ATTR{idProduct}=="a4a2", GROUP+="kvm"
            '';

            ghaf = {
              hardware.x86_64.common.enable = true;

              virtualization.microvm-host.enable = true;
              host.networking.enable = true;
              virtualization.microvm.netvm = {
                enable = true;
                extraModules = netvmExtraModules;
              };
              virtualization.microvm.dockervm = {
                enable = true;
              };

              # Enable all the default UI applications
              profiles = {
                applications.enable = true;
                #TODO clean this up when the microvm is updated to latest
                release.enable = variant == "release";
                debug.enable = variant == "debug";
              };
            };
          }

          {
            systemd.network.networks."10-virbr0".routes = lib.mkForce [
              { routeConfig.Gateway = "192.168.101.1"; }
            ];
          }

          formatModule

          #TODO: how to handle the majority of laptops that need a little
          # something extra?
          # SEE: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
          # nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen

          {
            boot.kernelParams = [
              "intel_iommu=on,igx_off,sm_on"
              "iommu=pt"

              # TODO: Change per your device
              # Passthrough Intel WiFi card
              "vfio-pci.ids=8086:a0f0"
            ];
          }
        ]
        ++ (import ../modules/fmo-module-list.nix)
        ++ (import ../modules/module-list.nix)
        ++ extraModules;
    };
  in {
    inherit hostConfiguration;
    name = "${name}-${variant}";
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  debugModules = [../modules/development/usb-serial.nix {ghaf.development.usb-serial.enable = true;}];
  targets = [
    (dell-7330-x86 "debug" debugModules)
    (dell-7330-x86 "release" [])
  ];
in {
  nixosConfigurations =
    builtins.listToAttrs (map (t: lib.nameValuePair t.name t.hostConfiguration) targets);
  packages = {
    x86_64-linux =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.package) targets);
  };
}
