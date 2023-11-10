# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ghafOS}:{
  config,
  lib,
  ...
}: let
  configHost = config;
  vmName = "docker-vm";
  macAddress = "02:00:00:01:01:02";
  dockervmBaseConfiguration = {
    imports = [
      (import "${ghafOS}/modules/virtualization/microvm/common/vm-networking.nix" {inherit vmName macAddress;})
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

        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        time.timeZone = "Asia/Dubai";

        microvm.hypervisor = "qemu";

        systemd.network.links."10-ethint0" = {
          extraConfig = "MTUBytes=1460";
        };

        systemd.network = {
          networks."10-ethint0" = {
            addresses = [
              {                          
                # IP-address for debugging subnet                                      
                addressConfig.Address = "192.168.101.11/24";                           
              }                          
            ];             
            routes =  [                
              { routeConfig.Gateway = "192.168.101.1"; }                               
            ];
          };
        };

        services =
        {
          dci = {
            enable = true;
            compose-path = "/var/lib/fogdata/docker-compose.yml";
            pat-path = "/var/lib/fogdata/PAT.pat";
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
            postInstall-path = "/var/lib/fogdata";
            env-path = "/home/ghaf";
          };
          avahi.enable = true;
          avahi.nssmdns = true;
        };


	      microvm.volumes = [
	        {
            image = "/var/tmp/docker.img";
            mountPoint = "/var/lib/docker";
            size = 10240;
            autoCreate = true;
            fsType = "ext4";
	        }
	      ];
        microvm.optimize.enable = true;
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
        ];

        microvm.storeDiskType = "squashfs";
        microvm.mem = 4096;
        microvm.vcpu = 2;

        imports = (import "${ghafOS}/modules/module-list.nix") ++ (import ../../fmo-module-list.nix);
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
