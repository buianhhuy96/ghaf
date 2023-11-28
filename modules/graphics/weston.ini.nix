# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.weston;
  mkLauncher = {
    path,
    icon,
  }: ''
    [launcher]
    path=${path}
    icon=${icon}

  '';

  /*
  Generate launchers to be used in weston.ini

  Type: mkLaunchers :: [{path, icon}] -> string

  */
  mkLaunchers = lib.concatMapStrings mkLauncher;

  gala-app = pkgs.callPackage ../../user-apps/gala {};
  demoLaunchers = [
    # Add application launchers
    # Adding terminal launcher because it is overwritten if other launchers are on the panel
    {
      path = "${pkgs.weston}/bin/weston-terminal";
      icon = "${pkgs.weston}/share/weston/icon_terminal.png";
    }

    {
      path = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland 192.168.101.11";
      icon = "${pkgs.chromium}/share/icons/hicolor/24x24/apps/chromium.png";
    }

    {
      path = "/etc/xdg/weston/bin/nmLauncher";
      icon = "${pkgs.networkmanagerapplet}/share/icons/hicolor/22x22/apps/nm-device-wwan.png";
    }
  ];
in {
  options.ghaf.graphics.weston = with lib; {
    launchers = mkOption {
      description = "Weston application launchers to show in launch bar";
      default = [];
      type = with types;
        listOf
        (submodule {
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

  config = lib.mkIf cfg.enable {
    ghaf.graphics.weston.launchers = lib.optionals cfg.enableDemoApplications demoLaunchers;
    environment.systemPackages = with pkgs;
      lib.optionals cfg.enableDemoApplications [
        # Graphical applications
        # Probably, we'll want to re/move it from here later
        chromium
        element-desktop
        gala-app
        zathura
      ];
    environment.etc."xdg/weston/weston.ini" = {
      text =
        ''
          # Disable screen locking
          [core]
          idle-time=0

          [shell]
          locking=false
          background-image=${./assets/wallpaper.jpg}
          background-type=scale-crop

          # Enable Hack font for weston-terminal
          [terminal]
          font=Hack
          font-size=16

        ''
        + mkLaunchers cfg.launchers;

      # The UNIX file mode bits
      mode = "0644";
    };

    environment.etc."xdg/weston/bin/nmLauncher" = {
      source = let
        script = pkgs.writeShellScriptBin "nmLauncher" ''
          export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/ssh_session_dbus.sock
          export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/ssh_system_dbus.sock
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
      in "${script}/bin/nmLauncher";
      mode = "0555";
    };
  };
}
