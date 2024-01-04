# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.demo-apps;

  # Create a binary in /nix/store and it can be called by refering to its path in /nix/store 
  # ${nmLauncher}/bin/nmLauncher
  nmLauncher = pkgs.writeShellScriptBin "nmLauncher" ''
          export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/ssh_session_dbus.sock
          export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/ssh_system_dbus.sock
          ${pkgs.openssh}/bin/ssh-keygen -R 192.168.100.1
          ${pkgs.openssh}/bin/ssh -M -S /tmp/ssh_control_socket \
              -f -N -q ghaf@192.168.100.1 \
              -i /run/ssh-keys/id_ed25519 \
              -o StrictHostKeyChecking=no \
              -o StreamLocalBindUnlink=yes \
              -o ExitOnForwardFailure=yes \
              -L /tmp/ssh_session_dbus.sock:/run/user/1000/bus \
              -L /tmp/ssh_system_dbus.sock:/run/dbus/system_bus_socket
          ${pkgs.networkmanagerapplet}/bin/nm-connection-editor
          # Use the control socket to close the ssh tunnel.
          ${pkgs.openssh}/bin/ssh -q -S /tmp/ssh_control_socket -O exit ghaf@192.168.100.1
        '';

in {
  options.ghaf.graphics.demo-apps = with lib; {   
   launchers = mkOption {
      description = "Weston application launchers to show in launch bar";
      default = [];
      type = with types;
        listOf
        (submodule {
          options.name = mkOption {
            description = "Name of executable when hovering the mouse over the icon";
            type = str;
          };
          options.package = mkOption {
            description = "Package to be added to environment.systemPackages";
            type = listOf package;
            default = [];
          };
          options.path = mkOption {
            description = "Path to the executable to be launched";
            type = path;
          };
          options.icon = mkOption {
            description = "Path of the icon";
            type = path;
          };
          
        });
    };
    enableDemoApplications = mkEnableOption "some applications for demoing";
  };
  
  config = lib.mkIf cfg.enableDemoApplications {
    ghaf.graphics.demo-apps.launchers = [
        {
          name = "Chromium";
          path = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland 192.168.101.11";
          icon = "${pkgs.chromium}/share/icons/hicolor/48x48/apps/chromium.png";
          package = [pkgs.chromium];
        }
        {
          name = "Foot";
          path = "${pkgs.foot}/bin/foot";
          icon = "${pkgs.foot}/share/icons/hicolor/48x48/apps/foot.png";
          package = [pkgs.foot];
        }
        {
          name = "nmLauncher";
          path = "${nmLauncher}/bin/nmLauncher";
          icon = "${pkgs.networkmanagerapplet}/share/icons/hicolor/22x22/apps/nm-device-wwan.png";
          package = [nmLauncher pkgs.networkmanagerapplet];          
        }
        ];
    environment.systemPackages = lib.lists.flatten (
      builtins.map (launcher: launcher.package) config.ghaf.graphics.demo-apps.launchers);
      
    # Needed for nm-applet as defined in 
    # https://github.com/NixOS/nixpkgs/blob/4cdde2bb35340a5b33e4a04e3e5b28d219985b7e/nixos/modules/programs/nm-applet.nix#L22
    # Requires further testing 
    services.dbus.packages = [ pkgs.gcr ];
  };
}