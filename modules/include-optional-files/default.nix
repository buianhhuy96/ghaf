# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
  cfg = config.services.file-list;
    
in
{
  options.services.file-list = {
    enable = mkEnableOption "Include optional files";

    enabledFiles = mkOption {
      description = mdDoc ''
        Sequence of enabled modules.
      '';
      type = with types; listOf(str);
      default = [];
    };

    file-info = mkOption{
      type = with types; attrsOf (submodule {
        options = {  
          src-path = mkOption {
            type = types.nullOr (types.oneOf [types.path types.set]);
            description = "Path to source file to copy";
            default = null;
          };          
          des-path  = mkOption {
            type = types.path;
            default = "${config.users.users.ghaf.home}";
            description = "Path to paste output files";
          };
          permission  = mkOption {
            type = types.str;
            default = "755";
            description = "File permission";
          };
        };
      });
      };
  };

  config.systemd =  mkIf (cfg.enable && cfg.enabledFiles != []) (
        let
          systemdConfig = map (filename:  
            let 
              src = cfg.file-info.${filename}.src-path;
              des = cfg.file-info.${filename}.des-path;
              permission = cfg.file-info.${filename}.permission;
              namingCondition = (mkMerge [ 
                    (mkIf ((builtins.typeOf src) == "set") 
                      filename)     

                    (mkIf ((builtins.typeOf src) == "path") 
                      (builtins.baseNameOf src))
                    (mkIf (src == null) 
                      (builtins.baseNameOf src))
                ]).contents;
              srcName =  ((builtins.elemAt (builtins.filter (c: c.condition) namingCondition) 0).content);

            in {
              services.${filename} = {  
                description = "Copy custom files to destination folder and set permission";
                serviceConfig = {
                  Type = "oneshot";
                  ExecStartPre = ''
                    ${pkgs.coreutils}/bin/mkdir -p ${des}
                    '';
                  ExecStart = (mkMerge [ 
                    (mkIf ( (builtins.typeOf src) == "set") 
                      (''
                        ${pkgs.findutils}/bin/find "${src.outPath}/" -mindepth 1 -exec install -m ${permission} {} ${des} \;
                      ''))     
 
                    (mkIf ( builtins.typeOf src == "path") 
                      (''
                        ${pkgs.findutils}/bin/find "${src}" -mindepth 1 -exec install -m ${permission} {} ${des} \;
                      ''))  
                    (mkIf ( src == null) 
                      (''
                        ${pkgs.coreutils}/bin/chmod -R ${permission} "${des}"
                      ''))                  
                  ]);
                };
                wantedBy = [ "multi-user.target" ]; 
                enable = true;
              };
            }
          ) cfg.enabledFiles;  
    in
    builtins.foldl' recursiveUpdate {}  systemdConfig    
  );
    
}
    