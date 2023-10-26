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
          enabledFiles = [ "registration-agent-env" "registration-agent-certs"];
          file-info = {
            # Write .env file into env-path
            registration-agent-env = { 
              src-path = pkgs.writeTextDir ".env" ''
                REGISTRATION_AGENT_DEVICE_REGISTERED_PATH=${cfg.certs-path}/registered.json
                REGISTRATION_AGENT_SERVICE_KEY_PATH=${cfg.certs-path}/client.key
                REGISTRATION_AGENT_SERVICE_CLIENT_CERTIFICATE_PATH=${cfg.certs-path}/client.pem
                REGISTRATION_AGENT_SERVICE_CA_CERTIFICATE_PATH=${cfg.certs-path}/ca.pem
                REGISTRATION_AGENT_SERVICE_NATS_URL_PATH=${cfg.certs-path}/nats-url.txt
                REGISTRATION_AGENT_DEVICE_TYPE=laptop
                REGISTRATION_AGENT_DEVICE_CONFIG_PATH=${cfg.config-path}/docker_compose.yml
                REGISTRATION_AGENT_SERVICE_SERVER_CERTIFICATE_PATH=${cfg.certs-path}/server.pem
                REGISTRATION_AGENT_SERVICE_SERVER_CA_CERTIFICATE_PATH=${cfg.certs-path}/server_ca.pem
                REGISTRATION_AGENT_SERVICE_SWARM_CA_CERTIFICATE_PATH=${cfg.certs-path}/swarm_ca.pem
                REGISTRATION_AGENT_SERVICE_SWARM_CA_KEY_PATH=${cfg.certs-path}/swarm_ca.key.pem
                REGISTRATION_AGENT_DEVICE_CONFIG_TOKEN_PATH=${cfg.token-path}/token.txt
                REGISTRATION_AGENT_DEVICE_HOSTNAME_PATH=${cfg.hostname-path}/hostname
                REGISTRATION_AGENT_ENABLE_MDNS=true
              '';
              des-path = cfg.env-path;
              permission = "777";
            };

            # Create and set permission of certs-path, config-path, token-path, hostname-path
            # If already created ignore the folder
            registration-agent-certs = { 
              src-path = null;
              des-path = cfg.certs-path;
              permission = "777";
            };
            registration-agent-config = { 
              src-path = null;
              des-path = cfg.config-path;
              permission = "777";
            };
            registration-agent-token = { 
              src-path = null;
              des-path = cfg.token-path;
              permission = "777";
            };
            registration-agent-hostname = { 
              src-path = null;
              des-path = cfg.hostname-path;
              permission = "777";
            };
          };
        };

        systemd = {
          # Service that reads wireless interface and write to .env
          services.registration-agent-network-interface = {  
            description = "Create environment-variable file for registration-agent-laptop";
            after = [
               "registration-agent-env.service" 
               "registration-agent-certs.service"
               "registration-agent-config.service"
               "registration-agent-token.service"
               "registration-agent-hostname.service"
            ];
            serviceConfig = {
              Type = "idle";
              ExecStart = ''
                ${pkgs.bash}/bin/bash -c 'echo REGISTRATION_AGENT_NETWORK_INTERFACE=$(ls -A /sys/class/ieee80211/*/device/net/ 2>/dev/null) >> ${cfg.env-path}/.env'
                '';
            };
            wantedBy = [ "multi-user.target" ]; 
            enable = true;
          };

          # Service that execute registration-agent binary on boot
          services.registration-agent-execution = mkIf (cfg.runOnBoot) { 
            description = "Create environment-variable file for registration-agent-laptop";
            after = [
               "registration-agent-network-interface.service"
            ];
            serviceConfig = {
              Type = "idle";
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
  