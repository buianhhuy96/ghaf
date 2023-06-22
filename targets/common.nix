# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Common modules for all targets
{
  imports = [
    # TODO: Add modules common to all targets here in the future
    ../modules/users/accounts.nix
    {
      ghaf.users.accounts.enable = true;
    }
    ../modules/version
  ];
}
