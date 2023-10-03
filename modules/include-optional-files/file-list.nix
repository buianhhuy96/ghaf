{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
  # TO-BE-REMOVED
  # This is only use as example
  example-local = ./file.txt;
  example-local2 = ./test;
  example-git = fetchGit {
      url = "https://github.com/docker-library/httpd";
      ref = "master";
      rev = "242f3c62ba1ceee0a3633045fc4fd9277cb86cd3";
    }; 

in   
{
  config.services.file-list = {
    # TO-USE
    # 1. Set enable = true;
    # 2. enableFiles = [ "<name of the folder if src is fetched link>"  ]
    # 3. create a set
    #   file-info.<name-in-enableFiles> =
    #        { src-path = <local-file or git>; des-path = <destination-to-copy-to>}
    # 4. git add <local-file> 
    enable = false;
    enabledFiles = [ "http" "test-folder" "test-file"];
    file-info = {
      http = { 
        src-path = example-git;
        des-path = "${config.users.users.ghaf.home}/to-be-deleted";};
      test-folder = { 
        src-path = example-local2;
        des-path = "${config.users.users.ghaf.home}/to-be-deleted";};
      test-file = { 
        src-path = example-local;
        des-path = "/var/netvm";};
    };
  };
}