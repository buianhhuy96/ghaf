{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
  letInclude = config.services.include-files;
   #example-local-path = ./files;
   example-git = fetchGit {
     url = "https://github.com/docker-library/httpd";
     ref = "master";
     rev = "242f3c62ba1ceee0a3633045fc4fd9277cb86cd3";
   }; 

in
{
  options.services.include-files = rec {
    enable = mkEnableOption "Include optional files";
    git-path = mkOption {
      type = types.path;
      description = "Path to source file to copy";
    };

    src-path = mkOption {
      type = types.path;
      description = "Path to source file to copy";
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
  config.environment.etc."custom-files" = {
    source = letInclude.src-path;
    # The UNIX file mode bits
    mode = "0644";
    };

  # A note with "environment.etc.<name>": 
  #   it is having a bug that not allow to create a folder. Please refer issue:
  #   https://github.com/NixOS/nixpkgs/issues/200744
  # Therefore, instead of create a symlink to files in /etc/, we link to /nix/store/ where 
  # the source files are.
  config.systemd.services = {
    "include-files" = {
      description = "Create symlink to custom files";
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = ''
          ${pkgs.coreutils}/bin/mkdir -p ${letInclude.des-path}
          '';
        ExecStart = ''
          ${pkgs.coreutils}/bin/ln -s ${config.environment.etc."custom-files".source} ${letInclude.des-path}
        '';
      };
      wantedBy = [ "multi-user.target" ]; 
      enable = true;
    };
  };

  #########################################
  ##### Implementation ####


  config.services.include-files = {
    enable = true;

  # For local path, the files must be staged before adding.
  #  src-path = example-local-path;
  
  # For "fetchGit"
    src-path = example-git.outPath;
  };


}