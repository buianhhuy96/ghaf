# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  netvmBaseConfiguration = {
    imports = [
      ({lib, ...}: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          development = {
            # NOTE: SSH port also becomes accessible on the network interface
            #       that has been passed through to NetVM
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };

        # SSH is very picky about the file permissions and ownership and will
        # accept neither direct path inside /nix/store or symlink that points
        # there. Therefore we copy the file to /etc/ssh/get-auth-keys (by
        # setting mode), instead of symlinking it.
        environment.etc."ssh/get-auth-keys" = {
          source = let
            script = pkgs.writeShellScriptBin "get-auth-keys" ''
              [[ "$1" != "ghaf" ]] && exit 0
              ${pkgs.coreutils}/bin/cat /run/ssh-public-key/id_ed25519.pub
            '';
          in "${script}/bin/get-auth-keys";
          mode = "0555";
        };
        services.openssh = {
          authorizedKeysCommand = "/etc/ssh/get-auth-keys";
          authorizedKeysCommandUser = "nobody";
        };

        networking.hostName = "netvm";
        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        microvm.hypervisor = "qemu";

        services.udev.extraRules = ''
          # Add usb to kvm group
          SUBSYSTEM=="net", ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idProduct}=="a4a2", ATTRS{idVendor}=="0525", NAME="mesh0"
          SUBSYSTEM=="net", ACTION=="add", DRIVERS=="e1000e", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", NAME="eth0"
        '';

        microvm.qemu.extraArgs = [
          "-usb"
          "-device"
          "usb-host,vendorid=0x0525,productid=0xa4a2"
        ];

        services =
        {
          portforwarding-service = {
            enable = true;
            ipaddress-path = "/etc/NetworkManager/system-connections/ip-address";
            configuration = [
              {
                dip = "192.168.101.11";
                dport = "4222";
                sport = "4222";
                proto = "tcp";
              }
              {
                dip = "192.168.101.11";
                dport = "7222";
                sport = "7222";
                proto = "tcp";
              }
              {
                dip = "192.168.101.11";
                dport = "4223";
                sport = "4223";
                proto = "tcp";
              }
            ];
          };

          avahi = {
            enable = true;
            nssmdns = true;
            reflector = true;
          };
        };

        networking = {
          enableIPv6 = false;
          interfaces.ethint0.useDHCP = false;
          firewall.allowedTCPPorts = [22];
          firewall.allowedUDPPorts = [67 5353];
          useNetworkd = true;
          useDHCP = false;
        };

        networking.networkmanager = {
          enable=true;
          unmanaged = [
            "ethint0"
          ];
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
          internalIPs = [ "192.168.0.0/16" ];
        };

        # Set internal network's interface name to ethint0
        systemd.network.links."10-ethint0" = {
          matchConfig.PermanentMACAddress = "02:00:00:01:01:01";
          linkConfig.Name = "ethint0";
          extraConfig = "MTUBytes=1460";
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

	microvm.shares = [
          {
	    # On the host
	    source = "/var/netvm/netconf";
	    # In the MicroVM
	    mountPoint = "/etc/NetworkManager/system-connections";
	    tag = "netconf";
	    proto = "virtiofs";
	    socket = "netconf.sock";
	  }

          # Use host's /nix/store to reduce size of the image
          {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }

          {
            tag = "ssh-public-key";
            source = "/run/ssh-public-key";
            mountPoint = "/run/ssh-public-key";
          }
        ];
        microvm.writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";
        fileSystems."/run/ssh-public-key".options = ["ro"];

        microvm.qemu.bios.enable = false;
        microvm.storeDiskType = "squashfs";

        imports = import ../../module-list.nix;
      })
    ];
  };
  cfg = config.ghaf.virtualization.microvm.netvm;
in {
  options.ghaf.virtualization.microvm.netvm = {
    enable = lib.mkEnableOption "NetVM";

    extraModules = lib.mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        NetVM's NixOS configuration.
      '';
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."netvm" = {
      autostart = true;
      config =
        netvmBaseConfiguration
        // {
          imports =
            netvmBaseConfiguration.imports
            ++ cfg.extraModules;
        };
      specialArgs = {inherit lib;};
    };

  systemd.services."psk-ssh-keygen" = let
    keygenScript = pkgs.writeShellScriptBin "psk-ssh-keygen" ''
      set -xeuo pipefail
      mkdir -p /run/ssh-keys
      echo -en "\n\n\n" | ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /run/ssh-keys/id_ed25519 -C ""
      chown ghaf:ghaf /run/ssh-keys/*
      cp /run/ssh-keys/id_ed25519.pub /run/ssh-public-key/id_ed25519.pub
    '';
  in {
    enable = true;
    description = "Generate SSH keys for Waypipe";
    path = [keygenScript];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "journal";
      StandardError = "journal";
      ExecStart = "${keygenScript}/bin/psk-ssh-keygen";
    };
  };

 # This directory needs to be created before any of the microvms start.
    systemd.services."create-ssh-public-key-directory" = let
    script = pkgs.writeShellScriptBin "create-ssh-public-key-directory" ''
      mkdir -pv /run/ssh-public-key
      chown -v microvm /run/ssh-public-key
    '';
  in {
    enable = true;
    description = "Create shared directory on host";
    path = [];
    wantedBy = ["microvms.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "journal";
      StandardError = "journal";
      ExecStart = "${script}/bin/create-ssh-public-key-directory";
    };
  };

  };
}
