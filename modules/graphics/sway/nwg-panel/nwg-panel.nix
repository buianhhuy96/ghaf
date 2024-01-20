# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.sway;
  mkLauncherModule = (launcher:
    "button-${lib.strings.toLower launcher.name}");

  mkLauncher = (launcher:
    {
    "button-${lib.strings.toLower launcher.name}" =  {
          command =  "${launcher.path}";
          icon = "${launcher.icon}";
          label = "";
          label-position = "bottom";
          tooltip = "${launcher.name}";
          css-name = "";
          icon-size = 36;
        };
    });

  /*
  Generate launchers to be used in weston.ini

  Type: mkLaunchers :: [{path, icon}] -> string

  */
  mkLaunchers = builtins.map mkLauncher;
  mkLauncherModules = builtins.map mkLauncherModule;

  launchers = builtins.foldl' lib.recursiveUpdate {} (mkLaunchers config.ghaf.graphics.demo-apps.launchers);
  launcherIcons = {
    modules-left = (mkLauncherModules config.ghaf.graphics.demo-apps.launchers);
  };

  panelTopConfig = builtins.elemAt (builtins.fromJSON ( builtins.readFile ./config)) 0;
  panelBottomConfig = builtins.elemAt (builtins.fromJSON ( builtins.readFile ./config)) 1;
  
  panelConfig = builtins.toJSON [
                  (panelTopConfig // launchers // launcherIcons) 
                  panelBottomConfig
                  ];
  
  panelConfigFile =  pkgs.writeText "config" panelConfig;

  panelAppWrapped = pkgs.symlinkJoin {
    name = "nwg-panel";
    paths = [ pkgs.nwg-panel ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nwg-panel \
        --add-flags "-c /etc/xdg/nwg-panel/config -s /etc/xdg/nwg-panel/style.css"
    '';
  };


in {
  
  config =  lib.mkIf cfg.enable {
    
    #environment.etc."xdg/nwg-panel/config" = {
    #  text = panelConfig;
    #  # The UNIX file mode bits
    #  mode = "0644";
    #};
    #
    #environment.etc."xdg/nwg-panel/style.css" = {
    #  source = ./style.css;
    #  # The UNIX file mode bits
    #  mode = "0644";
    #};

    services.file-list = {
      enable = true;
      enabledFiles = [ "nwg-panel-config" "nwg-panel-style" ];
      file-info = {
        nwg-panel-config = {
          #src-path = (pkgs.writeText "config" panelConfig).outPath;
          src-path = panelConfigFile;
          des-path = "${config.users.users.ghaf.home}/.config/nwg-panel";
          owner = config.ghaf.users.accounts.user;
          permission = "666";
        };
        nwg-panel-style = { 
          src-path = ./style;
          des-path = "${config.users.users.ghaf.home}/.config/nwg-panel";
          owner = config.ghaf.users.accounts.user;
          permission = "666";
        };
      };
    };

    environment.systemPackages = with pkgs;
      [
        gopsuinfo
        nwg-menu
        nwg-panel
      ];

  };
}
