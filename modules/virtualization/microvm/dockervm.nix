# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  dockervmBaseConfiguration = {
    imports = [
      ({lib, ...}: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          development = {
            # NOTE: SSH port also becomes accessible on the network interface
            #       that has been passed through to DockerVM
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

        networking.hostName = "dockervm";
        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        microvm.hypervisor = "qemu";

        microvm.qemu.extraArgs = [
          "-usb"
          "-device"
          "usb-host,vendorid=0x1546,productid=0x01a9"
        ];

        networking = {
          enableIPv6 = false;
          interfaces.ethint0.useDHCP = false;
          # TODO: fix firewall
#          firewall.allowedTCPPorts = [22 80 8080 8888 4280 4222 5432];
#          firewall.allowedUDPPorts = [22 80 8080 8888 4280 4222 5432];
          firewall.enable = false;
          useNetworkd = true;
        };

        microvm.interfaces = [
          {
            type = "tap";
            id = "vm-dockervm";
            mac = "02:00:00:01:01:02";
          }
        ];

        networking.nat = {
          enable = true;
          internalInterfaces = ["ethint0"];
        };

        # Set internal network's interface name to ethint0
        systemd.network.links."10-ethint0" = {
          matchConfig.PermanentMACAddress = "02:00:00:01:01:02";
          linkConfig.Name = "ethint0";
          extraConfig = "MTUBytes=1460";
        };

        systemd.network = {
          enable = true;
          networks."10-ethint0" = {
            matchConfig.MACAddress = "02:00:00:01:01:02";
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

        services =
        {
          dci = {
            enable = true;
            compose-path = "/var/lib/fogdata/docker-compose.yml";
            pat-path = "/var/lib/fogdata/PAT.pat";
            preloaded-images = "tii-offline-map-data-loader.tar.gz";
          };

          hostname-service = {
            enable = true;
            hostname-path = "/var/lib/fogdata/hostname";
          };

          registration-agent = {
            enable = true;
            runOnBoot = true;
            # env-path is the location of .env
            # while the other path is for the environment variables defined in .env
            certs-path = "/var/lib/fogdata/certs";
            config-path = "/var/lib/fogdata";
            token-path = "/var/lib/fogdata";
            hostname-path = "/var/lib/fogdata";
            ip-path = "/var/lib/fogdata";
            postInstall-path = "/var/lib/fogdata/certs";
            env-path = "/home/ghaf";
          };

          avahi.enable = true;
          avahi.nssmdns = true;
        };


	microvm.volumes = [
	  {
            image = "/var/tmp/docker.img";
            mountPoint = "/var/lib/docker";
            size = 51200;
            autoCreate = true;
            fsType = "ext4";
	  }
	];

	microvm.shares = [
          {
	    # On the host
	    source = "/var/foghyper";
	    # In the MicroVM
	    mountPoint = "/var/lib/foghyper/fog_system/conf";
	    tag = "foghyperfs";
	    proto = "virtiofs";
	    socket = "foghyperfs.sock";
	  }

	  {
	    # On the host
	    source = "/var/fogdata";
	    # In the MicroVM
	    mountPoint = "/var/lib/fogdata";
	    tag = "fogdatafs";
	    proto = "virtiofs";
	    socket = "fogdata.sock";
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
        microvm.mem = 4096;
        microvm.vcpu = 2;

        imports = (import ../../module-list.nix) ++ (import ../../fmo-module-list.nix);
      })
    ];
  };
  cfg = config.ghaf.virtualization.microvm.dockervm;
in {
  options.ghaf.virtualization.microvm.dockervm = {
    enable = lib.mkEnableOption "DockerVM";

    extraModules = lib.mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        Docker's NixOS configuration.
      '';
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."dockervm" = {
      autostart = true;
      config =
        dockervmBaseConfiguration
        // {
          imports =
            dockervmBaseConfiguration.imports
            ++ cfg.extraModules;
        };
      specialArgs = {inherit lib;};
    };
  };
}
