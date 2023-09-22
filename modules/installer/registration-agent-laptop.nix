# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs}:
let 
  buildGo121Module = pkgs.darwin.apple_sdk_11_0.callPackage ../golang/module.nix {
    go = go_1_21;
  };
  go_1_21= pkgs.darwin.apple_sdk_11_0.callPackage ../golang/1.21.nix {
    inherit (pkgs.darwin.apple_sdk_11_0.frameworks) Foundation Security;
    buildGo121Module = buildGo121Module;
  };

in
buildGo121Module {
  name = "registration-agent-laptop";
  src = builtins.fetchGit {
    url = "https://github.com/tiiuae/registration-agent-laptop/";
    rev = "fec3dfce76707c8f8541b69996ea1f09d474c16d";
  };
  vendorSha256 = "sha256-azmIkOfmHLL+xM9mJabsUT0EJTKoI97Sq1lKARG5cU8=";
  proxyVendor=true;
    # ...
}
