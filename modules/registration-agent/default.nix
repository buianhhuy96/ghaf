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
    env-path = lib.strings.removeSuffix ("/"+(builtins.baseNameOf cfg.certs-path)) cfg.certs-path;
     
    
    registrationAgent = pkgs.callPackage ./registration-agent-laptop-with-env.nix  {
       inherit pkgs; 
       env-path = lib.strings.removeSuffix (builtins.baseNameOf cfg.certs-path) cfg.certs-path;
     };
in
  with lib; {
    options.services.registration-agent = {
      enable = mkEnableOption "Install and setup registration-agent on system";

      certs-path = mkOption {
        type = types.path;
        default = "${config.users.users.ghaf.home}/certs";
        description = "Path to certificate files";
      };

      config-path = mkOption {
        type = types.path;
        default = "${config.users.users.ghaf.home}/config";
        description = "Path to config files";
      };
    };

    config = mkIf cfg.enable {
      environment.systemPackages = [registrationAgent];
      systemd.services.registration-agent-env = {  
          description = "Create environment-variable file for registration-agent-laptop";
          serviceConfig = {
            Type = "idle";
            ExecStartPre = ''${pkgs.bash}/bin/bash -c 'cat <<< "REGISTRATION_AGENT_PROVISIONING_URL=http://localhost:80/api/devices/provision\
\nREGISTRATION_AGENT_DEVICE_REGISTERED_PATH=${cfg.certs-path}/registered.json\
\nREGISTRATION_AGENT_SERVICE_KEY_PATH=${cfg.certs-path}/client.key\
\nREGISTRATION_AGENT_SERVICE_CLIENT_CERTIFICATE_PATH=${cfg.certs-path}/client.pem\
\nREGISTRATION_AGENT_SERVICE_CA_CERTIFICATE_PATH=${cfg.certs-path}/ca.pem\
\nREGISTRATION_AGENT_SERVICE_NATS_URL_PATH=${cfg.certs-path}/nats-url.txt\
\nREGISTRATION_AGENT_DEVICE_TYPE=laptop\
\nREGISTRATION_AGENT_NETWORK_INTERFACE=$(${pkgs.coreutils}/bin/ls -A /sys/class/ieee80211/*/device/net/ 2>/dev/null)\
\nREGISTRATION_AGENT_DEVICE_CONFIG_PATH=${cfg.config-path}"> ${env-path}/.env' '';
            ExecStart = ''${pkgs.bash}/bin/bash -c '\
              ${pkgs.coreutils}/bin/mkdir -p -m777 ${cfg.certs-path} &&\
              ${pkgs.coreutils}/bin/chmod 777 ${env-path}/.env' '';
          };
          wantedBy = [ "multi-user.target" ]; 
          enable = true;
        };
    };
  }