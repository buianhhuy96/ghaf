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
          owner  = mkOption {
            type = types.nullOr types.str;
            default = "root";
            description = "Owner of newly created destination folder";
          };
          permission  = mkOption {
            type = types.nullOr types.str;
            default = null;
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
              # This should not be outPath,
              src-data = ((builtins.elemAt (builtins.filter (c: c.condition) (mkMerge [ 
                    (mkIf ( (builtins.typeOf src) == "set")                     
                      "${src.outPath}") 
                    (mkIf ( (builtins.typeOf src) == "path") 
                      "${src}")  
                      ]).contents) 0).content);
              mindepth = ((builtins.elemAt (builtins.filter (c: c.condition) (mkMerge [
                    (mkIf ( (builtins.readFileType src-data) != "directory")
                      "0")
                    (mkIf ( (builtins.readFileType src-data) == "directory")
                      "1")
                      ]).contents) 0).content);

            in {
              services.${filename} = {  
                description = ''
                  Copy/Create "${filename}" files to "${des}" folder and set permission
                  '';
                serviceConfig = 
                  {
                    Type = "oneshot";
                  } //
                  (mkMerge [
                    (mkIf ( cfg.file-info.${filename}.owner != "root")
                    {
                      User = cfg.file-info.${filename}.owner;
                      Group = "users";
                    })
                    (mkIf ( src == null && permission == null)
                    {
                      ExecStart = ''
                        ${pkgs.coreutils}/bin/mkdir -p ${des}
                        '';
                    })
                    (mkIf ( src == null && permission != null)
                    {
                      ExecStartPre = ''
                              ${pkgs.coreutils}/bin/mkdir -p ${des}
                              '';
                      ExecStart = ''
                          ${pkgs.coreutils}/bin/chmod -R ${permission} "${des}"
                        '';
                    })
                    (mkIf ( src != null && permission == null)
                    {
                      ExecStartPre = ''
                            ${pkgs.coreutils}/bin/mkdir -p ${des}
                            '';
                      ExecStart = ''
                        ${pkgs.findutils}/bin/find "${src-data}" -mindepth ${mindepth} -exec install {} ${des} \;
                        '';
                    })
                    (mkIf ( src != null && permission != null)
                    {
                      ExecStartPre = ''
                            ${pkgs.coreutils}/bin/mkdir -p ${des}
                            '';
                      ExecStart = ''
                        ${pkgs.findutils}/bin/find "${src-data}" -mindepth ${mindepth} -exec install -m ${permission} {} ${des} \;
                        '';
                    })  
                  ]);
                
                wantedBy = [ "multi-user.target" ]; 
                enable = true;
              };
            }
          ) cfg.enabledFiles;  
    in
    builtins.foldl' recursiveUpdate {}  systemdConfig    
  );
    
}
    