# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.dci;
in {
  options.services.dci = {
    enable = mkEnableOption "DCI service";

    pat-path = mkOption {
      type = types.str;
      description = "Path to PAT .pat file";
    };
    compose-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    virtualisation.docker.enable = true;

    systemd.services.fmo-dci = {
    script = ''
        USR=$(${pkgs.gawk}/bin/gawk '{print $1}' ${cfg.pat-path})
        PAT=$(${pkgs.gawk}/bin/gawk '{print $2}' ${cfg.pat-path})
        DCPATH=$(echo ${cfg.compose-path} )

        echo "Login ghcr.io"

        echo $PAT | ${pkgs.docker}/bin/docker login ghcr.io -u $USR --password-stdin || echo 'login to ghcr.io failed continue as is'
        echo "Start docker-compose"
        ${pkgs.docker-compose}/bin/docker-compose -f $DCPATH up
      '';

      wantedBy = ["multi-user.target"];
      # If you use podman
      # after = ["podman.service" "podman.socket"];
      # If you use docker
      after = [
        "docker.service" 
        "docker.socket"
        "network-online.target"
      ] 
      ++ optionals config.services.registration-agent.enable  [ "fmo-registration-agent-execution.service" ];
      
      # TODO: restart always
      serviceConfig = {
        Restart = lib.mkForce "always";
        RestartSec = "30";
      };
    };
  };
}
