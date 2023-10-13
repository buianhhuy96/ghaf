# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  env-path,
}:
let
  registrationAgentOrig = pkgs.callPackage ./registration-agent-laptop.nix {inherit pkgs;};
in
pkgs.writeScriptBin "registration-agent-laptop" ''
      #${pkgs.bash}/bin/bash
      function usage() { 
        echo "Usage: $0 [-e <absolute-path-to-env-file>]"; exit 1;
      }
      while getopts ":e:" o; do
          case "''${o}" in
              e)
                  env=''${OPTARG}
                  ;;
              
              *)
                  usage
                  ;;
          esac
      done
      shift $((OPTIND-1))

      if [ -z "''${env}" ] 
      then
        env=${env-path}/.env
      fi

      echo "Use environment variables located at ''${env}"
      export $(cat "''${env}")
      ${registrationAgentOrig}/bin/registration-agent-laptop-orig
      ''