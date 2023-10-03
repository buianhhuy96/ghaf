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

  imports = [ ./file-list.nix];
  options.services.file-list = {
    enable = mkEnableOption "Include optional files";

    enabledFiles = lib.mkOption {
      description = lib.mdDoc ''
        Sequence of enabled modules.
      '';
      type = with lib.types; listOf(str);
      default = "";
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
            default = "${config.users.users.ghaf.home}/include";
            description = "Path to paste output files";
          };
        };
      });
      };
  };

  config = lib.mkIf cfg.enable ( {
    environment = builtins.foldl' lib.recursiveUpdate {}  (let 
          src = name: cfg.file-info.${name}.src-path;
          enabledSrc = map src cfg.enabledFiles;
        in 
          lib.lists.zipListsWith (filename: src: {
            etc.${filename} =
                (mkMerge [ 
                    (mkIf ( (builtins.typeOf src) == "set") 
                      { source = src.outPath; })     

                    (mkIf ( builtins.typeOf src == "path") 
                      { source = src; })

                    {
                      # The UNIX file mode bits
                      mode = "0644";
                    }
                ]);
          }) cfg.enabledFiles enabledSrc  
        );
    systemd = builtins.foldl' lib.recursiveUpdate {}  (let 
          des = name: cfg.file-info.${name}.des-path;
          enabledDes = map des cfg.enabledFiles;
          
        in 
          lib.lists.zipListsWith (filename: des: {
            services = let 

              src = cfg.file-info.${filename}.src-path;
              condition4Name = (mkMerge [ 
                    (mkIf ((builtins.typeOf src) == "set") 
                      filename)     

                    (mkIf ((builtins.typeOf src) == "path") 
                      (builtins.baseNameOf src))
                ]).contents;
              srcName =  ((builtins.elemAt (builtins.filter (c: c.condition) condition4Name) 0).content);
             in
             {  
              ${filename} = {
                description = "Create symlink to custom files";
                serviceConfig = {
                  Type = "oneshot";
                  ExecStartPre = ''
                    ${pkgs.coreutils}/bin/mkdir -p ${des}
                    '';
                  ExecStart = 
                    (''
                    ${pkgs.coreutils}/bin/ln -s ${config.environment.etc.${filename}.source} "${des}/${srcName}"
                    '');
                  
                };
                wantedBy = [ "multi-user.target" ]; 
                enable = true;
              };
            };
        }) cfg.enabledFiles enabledDes
    );
  });
    
  }
    