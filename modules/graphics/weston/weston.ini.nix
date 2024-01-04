# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.weston;
  weston-bar = pkgs.callPackage ./weston-bar.nix {};
  # Weston 12 required for the bar to work. So use as a package here
  # To be deleted when update to nixpkgs-23.11
  weston-12= pkgs.callPackage ./weston-12/weston-12.0.2.nix {};

  mkLauncher = (launcher:
  ''
    [launcher]
    path=${launcher.path}
    icon=${launcher.icon}

  '');

  /*
  Generate launchers to be used in weston.ini

  Type: mkLaunchers :: [{path, icon}] -> string

  */
  mkLaunchers = lib.concatMapStrings mkLauncher;

  #gala-app = pkgs.callPackage ../../user-apps/gala {};
in {
  config = lib.mkIf cfg.enable {
    ghaf.graphics.demo-apps.launchers = [{
        name = "Weston terminal";
        path = "${weston-12}/bin/weston-terminal";
        icon = "${weston-12}/share/weston/icon_terminal.png";
        package = [weston-12];
      }];

    environment.etc."xdg/weston/weston.ini" = {
      text =
        ''
          # Disable screen locking
          [core]
          idle-time=0
          modules=${weston-bar}/lib/shell_helper.so
  
          [shell]
          client=${weston-bar}/bin/weston-bar
          locking=false
          background-image=${../assets/wallpaper.jpg}
          background-type=scale-crop
          animation=none
          close-animation=none
          startup-animation=none
          focus-animation=none
          panel-position=bottom
          default_icon=${weston-bar.src}/source/icons
  
          [libinput]
          enable-tap=true
  
          # Enable Hack font for weston-terminal
          [terminal]
          font=Hack
          font-size=16
  
        ''
        + mkLaunchers config.ghaf.graphics.demo-apps.launchers;

      # The UNIX file mode bits
      mode = "0644";
    };

    # As I understand from this is: this binary is not supposed to be written (permission 555).
    # This means that we can use ${nmLauncher}/bin/nmLauncher directly as an application with needing to 
    # create a binary in /etc/xdg/...
    # In addition, I move it to demo-apps to sync with other apps.

    #environment.etc."xdg/weston/bin/nmLauncher" = {
    #  source = let
    #    script = pkgs.writeShellScriptBin "nmLauncher" ''
    #      export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/ssh_session_dbus.sock
    #      export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/ssh_system_dbus.sock
    #      ${pkgs.openssh}/bin/ssh-keygen -R 192.168.100.1
    #      ${pkgs.openssh}/bin/ssh -M -S /tmp/ssh_control_socket \
    #          -f -N -q ghaf@192.168.100.1 \
    #          -i /run/ssh-keys/id_ed25519 \
    #          -o StrictHostKeyChecking=no \
    #          -o StreamLocalBindUnlink=yes \
    #          -o ExitOnForwardFailure=yes \
    #          -L /tmp/ssh_session_dbus.sock:/run/user/1000/bus \
    #          -L /tmp/ssh_system_dbus.sock:/run/dbus/system_bus_socket
    #      ${pkgs.networkmanagerapplet}/bin/nm-connection-editor
    #      # Use the control socket to close the ssh tunnel.
    #      ${pkgs.openssh}/bin/ssh -q -S /tmp/ssh_control_socket -O exit ghaf@192.168.100.1
    #    '';
    #  in "${script}/bin/nmLauncher";
    #  mode = "0555";
    #};
  };
}