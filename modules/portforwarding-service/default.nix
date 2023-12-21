# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.portforwarding-service;

  mkPortForwardingRule = {dip, sport, dport, proto}: ''
    echo "Apply a new port forwarding: $IP:${sport} to ${dip}:${dport}"
    ${pkgs.iptables}/bin/iptables -I INPUT -p ${proto} --dport ${sport} -j ACCEPT
    ${pkgs.iptables}/bin/iptables -t nat -I PREROUTING -p tcp -d $IP --dport ${sport} -j DNAT --to-destination ${dip}:${dport}

  '';

in {
  options.services.portforwarding-service = {
    enable = mkEnableOption "portforwarding-service";

    ipaddress-path = mkOption {
      type = types.str;
      description = "Path to ipaddress file";
    };

    configuration = mkOption {
      type = types.listOf types.attrs;
      description = ''
        List of
          {
            dip = destanation IP address,
            sport = source port,
            dport = destanation port,
            proto = protocol (udp, tcp)
          }
      '';
    };

  };

  config = mkIf cfg.enable {
    systemd.services.fmo-portforwarding-service = {
      script = ''
          IP=$(${pkgs.gawk}/bin/gawk '{print $1}' ${cfg.ipaddress-path})

          ${ lib.concatStrings (map mkPortForwardingRule cfg.configuration) }
      '';

      wantedBy = ["network.target"];
    };
  };
}
