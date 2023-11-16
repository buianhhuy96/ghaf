# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs, 
config,
lib,
systemImgCfg,
...}: with lib;
let 
  cfg = config.installer.installerScript;

in
{
  options.installer.installerScript = {
    enable = mkEnableOption "Build and enable installer script";

    runOnBoot = mkOption {
      description = mdDoc ''
        Enable installing script to run on boot.
      '';
      type = types.bool;
      default = false;
    };

    systems = mkOption{
      type = with types; listOf (submodule {
        options = {  
          name = mkOption {
            type = types.str;
            description = "Name of the image";
            default = null;
          };   
          image = mkOption {
            type = types.attrs;
            description = "Image configuration";
            default = null;
          };     
        };
      });
      default = [];
    };
  };

  config.services.registration-agent = mkIf (cfg.enable && cfg.systems != []) {
    enable = true;
    certs-path = "/home/ghaf/root/var/fogdata/certs";
    config-path = "/home/ghaf/root/var/fogdata";
    token-path = "/home/ghaf/root/var/fogdata";
    hostname-path = "/home/ghaf/root/var/fogdata";
    ip-path = "/home/ghaf/root/var/fogdata";
    postInstall-path = "/var/lib/fogdata";
    env-path = "/var/fogdata";
  };

  config.environment = mkIf (cfg.enable && cfg.systems != []) (   
    let
      installerDir = ./src;
      registration-agent-laptop = pkgs.callPackage ../registration-agent/registration-agent-laptop-with-env.nix {
            inherit pkgs; 
            env-path = "${config.services.registration-agent.env-path}";
            };

      imageText = map (system: "${system.name}||${system.image.config.system.build.${system.image.config.formatAttr}}/nixos.img") cfg.systems; 
      imageListText = builtins.concatStringsSep "||" imageText;
      installerGoScript = pkgs.buildGo120Module {
        name = "ghaf-installer";
        src = ./src;
        vendorSha256 = "sha256-MKMsvIP8wMV86dh9Y5CWhgTQD0iRpzxk7+0diHkYBUo=";
        proxyVendor=true;
        ldflags = [
          "-X ghaf-installer/global.Images=${imageListText}"
          "-X ghaf-installer/screen.screenDir=${installerDir}/screen"
          "-X ghaf-installer/screen.certPath=${config.services.registration-agent.certs-path}"
          "-X ghaf-installer/screen.configPath=${config.services.registration-agent.config-path}"
          "-X ghaf-installer/screen.tokenPath=${config.services.registration-agent.token-path}"
          "-X ghaf-installer/screen.registrationAgentScript=${registration-agent-laptop}/bin/registration-agent-laptop"
        ];
      };
  in {
      systemPackages = [installerGoScript];
      loginShellInit = mkIf (cfg.runOnBoot) (''sudo ${installerGoScript}/bin/ghaf-installer'');
    });
}
