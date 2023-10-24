# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.portforwarding-service;
in {
  options.services.portforwarding-service = {
    enable = mkEnableOption "portforwarding-service";

    ipaddress-path = mkOption {
      type = types.str;
      description = "Path to ipaddress file";
    };

    dip = mkOption {
      type = types.str;
      description = "Destanation IP";
    };

    sport = mkOption {
      type = types.str;
      description = "Source port";
    };

    dport = mkOption {
      type = types.str;
      description = "Destanation port";
    };

  };

  config = mkIf cfg.enable {

    systemd.services.fmo-portforwarding-service = {
    script = ''
        IP=$(${pkgs.gawk}/bin/gawk '{print $1}' ${cfg.ipaddress-path})

        echo "Apply a new port forwarding: $IP:${cfg.sport} to ${cfg.dip}:${cfg.dport}"

        # TODO: open only used port
        ${pkgs.iptables}/bin/iptables -I INPUT -p tcp --dport ${cfg.sport} -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -I PREROUTING -p tcp -d $IP --dport ${cfg.sport} -j DNAT --to-destination ${cfg.dip}:${cfg.dport}
        ${pkgs.iptables}/bin/iptables -t nat -I POSTROUTING -p tcp -d ${cfg.dip} --dport ${cfg.dport} -j SNAT --to-source $IP:${cfg.sport}
      '';

      wantedBy = ["network.target"];
    };
  };
}
