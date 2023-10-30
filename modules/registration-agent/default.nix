# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
    cfg = config.services.registration-agent;
         
in
  with lib; {
    options.services.registration-agent = {
      enable = mkEnableOption "Install and setup registration-agent on system";

      runOnBoot = mkOption {
        description = mdDoc ''
          Enable registration agent to run on boot.
        '';
        type = types.bool;
        default = false;
       };

      certs-path = mkOption {
        type = types.path;
        default = "/var/fogdata/certs";
        description = "Path to certificate files, used for environment variables";
      };

      config-path = mkOption {
        type = types.path;
        default = "/var/fogdata";
        description = "Path to config file, docker-compose.yml, used for environment variables";
      };

      token-path = mkOption {
        type = types.path;
        default = "/var/fogdata/certs";
        description = "Path to token file, used for environment variables";
      };

      hostname-path = mkOption {
        type = types.path;
        default = "/var/fogdata";
        description = "Path to hostname file, used for environment variables";
      };

      env-path = mkOption {
        type = types.path;
        default = "/var/fogdata";
        description = "Path to put .env file";
      };
    };

    config =  let          
        registrationAgent = pkgs.callPackage ./registration-agent-laptop-with-env.nix  {
            inherit pkgs; 
            env-path = cfg.env-path;
          }; 
      in
      mkIf (cfg.enable) {
        environment.systemPackages = [registrationAgent];

        services.file-list = {
          enable = true;
          enabledFiles = [ 
            "fmo-registration-agent-env"
            "fmo-registration-agent-certs"
            "fmo-registration-agent-config"
            "fmo-registration-agent-hostname"
            "fmo-registration-agent-token"
            ];
          file-info = {
            # Write .env file into env-path
            fmo-registration-agent-env = { 
              src-path = pkgs.writeTextDir ".env" ''
                AUTOMATIC_PROVISIONING=false
                PROVISIONING_URL=
                DEVICE_ALIAS=
                DEVICE_IDENTITY_FILE=${cfg.certs-path}/identity.txt
                DEVICE_CONFIGURATION_FILE=${cfg.config-path}/docker_compose.yml
                DEVICE_AUTH_TOKEN_FILE=${cfg.token-path}/token.txt
                DEVICE_HOSTNAME_FILE=${cfg.hostname-path}/hostname
                DEVICE_ID_FILE=${cfg.certs-path}/device_id.txt
                FLEET_NATS_LEAF_CONFIG_FILE=${cfg.certs-path}/leaf.conf
                SERVICE_NATS_URL_FILE=${cfg.certs-path}/service_nats_url.txt
                SERVICE_IDENTITY_KEY_FILE=${cfg.certs-path}/identity.key
                SERVICE_IDENTITY_CERTIFICATE_FILE=${cfg.certs-path}/identity.crt
                SERVICE_IDENTITY_CA_FILE=${cfg.certs-path}/identity_ca.crt
                SERVICE_FLEET_LEAF_CERTIFICATE_FILE=${cfg.certs-path}/fleet.crt
                SERVICE_FLEET_LEAF_CA_FILE=${cfg.certs-path}/fleet_ca.crt
                SERVICE_SWARM_KEY_FILE=${cfg.certs-path}/swarm.key
                SERVICE_SWARM_CA_FILE=${cfg.certs-path}/swarm.crt
              '';
              des-path = cfg.env-path;
              permission = "666";
            };

            # Create and set permission of certs-path, config-path, token-path, hostname-path
            # If already created ignore the folder
            fmo-registration-agent-certs = { 
              src-path = null;
              des-path = cfg.certs-path;
            };
            fmo-registration-agent-config = { 
              src-path = null;
              des-path = cfg.config-path;
            };
            fmo-registration-agent-token = { 
              src-path = null;
              des-path = cfg.token-path;
            };
            fmo-registration-agent-hostname = { 
              src-path = null;
              des-path = cfg.hostname-path;
            };
          };
        };

        systemd = {
          # Service that reads wireless interface and write to .env
          services.fmo-registration-agent-network-interface = {  
            description = "Get network interface for registration-agent-laptop environment-variable";
            after = [
               "registration-agent-env.service" 
               "registration-agent-certs.service"
               "registration-agent-config.service"
               "registration-agent-token.service"
               "registration-agent-hostname.service"
            ];
            requires = ["registration-agent-env.service"];
            serviceConfig = {
              Type = "idle";
              ExecStart = ''
                ${pkgs.bash}/bin/bash -c 'echo NETWORK_INTERFACE=$(ls -A /sys/class/ieee80211/*/device/net/ 2>/dev/null) >> ${cfg.env-path}/.env'
                '';
            };
            wantedBy = [ "multi-user.target" ]; 
            enable = true;
          };

          # Service that execute registration-agent binary on boot
          services.fmo-registration-agent-execution = mkIf (cfg.runOnBoot) { 
            description = "Execute registration agent on boot for registration phase";
            after = [
               "registration-agent-network-interface.service"
               "network-online.target"
            ];
            requires = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              Restart="on-failure";
              RestartSec=5;
              ExecStart = ''
                ${pkgs.bash}/bin/bash -c '${registrationAgent}/bin/registration-agent-laptop'
              '';
            };
            wantedBy = [ "multi-user.target" ]; 
            enable = true;
          };

        };
      };  
  }
  