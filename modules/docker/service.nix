{
  pkgs,
  config,
  lib,
  ...
}: 
{
  # First attempt: manual systemd service config to start to created docker image fetched 
  # in modules/docker/httpd/default.nix 
  #########################################
  
  #config.systemd.services = {
  #  "docker-load" = {
  #    description = "Load custom docker images";
  #    requires = ["docker.service"];
  #    after = ["docker.service"];
  #    serviceConfig = {
  #      Restart="on-failure";
  #      RestartSec="3";
  #      Type = "oneshot";
  #      ExecStart = "${pkgs.docker}/bin/docker load --input=${pkgs.httpd}/my-docker-images/httpd.tar.gz";      
  #    };
  #    wantedBy = [ "multi-users.target" ]; 
  #    enable = true;
  #  };

  #  "docker-run" = {
  #    description = "Start docker containers from loaded images";
  #    requires = ["docker.service" "docker-load.service"];
  #    after = ["docker.service" "docker-load.service"];
  #    serviceConfig = {
  #      Restart="on-failure";
  #      RestartSec="3";
  #      Type = "oneshot";
  #      ExecStart = "${pkgs.docker}/bin/docker run --name my-running-app -p 8080:80 -d hello-docker";        
  #    };
  #    wantedBy = [ "multi-users.target" ];
  #    enable = true;
  #  };
  #};

  #config.systemd.services = {
  #  "docker-my-httpd" = {
  #    description = "Load and custom docker images";
  #    serviceConfig = {
  #      Type = "oneshot"; 
  #    };
  #    wantedBy = [ "multi-users.target" ]; 
  #    enable = true;
  #  };
  #};

  # Second attempt: Nix containers
  #########################################

  # Custom config for not stopping service (without this, 
  #  service will automatically stop and restart continuously)
  config.systemd.services.docker-my-httpd= {
    serviceConfig = {
      Restart = lib.mkForce "on-failure";
      RestartSec = lib.mkForce "3";
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Create container based on Docker.io image
  config.virtualisation.oci-containers.backend = "docker";
  config.virtualisation.oci-containers.containers = {
    "my-httpd" = {
      imageFile = pkgs.dockerTools.buildImage {
        name = "hello-docker";
        tag = "latest";
        fromImage = pkgs.dockerTools.pullImage {
          imageName = "httpd";
          imageDigest =
            "sha256:f499227681dff576d6ae8c49550c57f11970b358ee720bb8557b9fa7daf3a06d";
          sha256 = "sha256-Y80d+ibqzcC5IwzE6zrTCmrC1+4tgcoy3591qq4bZ9Q=";
        };
        config = {
          Cmd = [
           "httpd-foreground"
          ];
        }; 
      };
      image = "hello-docker:latest";
      autoStart = true;
      extraOptions = ["-p" "8080:80" "-d"];
    };
  };

}