# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
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

        networking.hostName = "dockervm";
        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        microvm.hypervisor = "qemu";

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
          };  

          registration-agent = {
            enable = true;
            certs-path = "/var/lib/fogdata/certs";
            config-path = "/var/lib/fogdata/config";
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
