{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
  letInclude = config.services.include-files;
   #example-local = ./files;
   example-git = fetchGit {
     url = "https://github.com/docker-library/httpd";
     ref = "master";
     rev = "242f3c62ba1ceee0a3633045fc4fd9277cb86cd3";
   }; 

in
{
  options.services.include-files = rec {
    enable = mkEnableOption "Include optional files";

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

  # To include files into nix image, there are only a few options with:
  # -   home.file.<name> - not possible as we are not using Home-Manager 
  # -   environment.etc.<name> - this creates files in /etc/ so it can work in our case
  config.environment.etc."custom-src" = 
    mkIf (config.services.include-files.src-path != null) (mkMerge [ 
      (mkIf ( (builtins.typeOf config.services.include-files.src-path) == "set") 
        { source = letInclude.src-path.outPath; })     
              
      (mkIf ( builtins.typeOf config.services.include-files.src-path == "path") 
        { source = letInclude.src-path; })
          
    {
      # The UNIX file mode bits
      mode = "0644";
    }
  ]);

  # A note with "environment.etc.<name>": 
  #   it is having a bug that not allow to create a folder. Please refer issue:
  #   https://github.com/NixOS/nixpkgs/issues/200744
  # Therefore, instead of create a symlink to files in /etc/, we link to /nix/store/ where 
  # the source files are.
  config.systemd.services = 
    mkIf (config.services.include-files.src-path != null)  {
    "include-files" = {
      description = "Create symlink to custom files";
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = ''
          ${pkgs.coreutils}/bin/mkdir -p ${letInclude.des-path}
          '';
        ExecStart = 
          (''
          ${pkgs.coreutils}/bin/ln -s ${config.environment.etc."custom-src".source} ${letInclude.des-path}
          '');
        
      };
      wantedBy = [ "multi-user.target" ]; 
      enable = true;
    };
  };

  #########################################
  ##### Implementation ####


  config.services.include-files = {
    enable = true;

    src-path = example-git;
    #src-path = example-local;
  };


}