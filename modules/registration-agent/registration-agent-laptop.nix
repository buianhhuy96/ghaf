# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs,lib}:
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
    url = "git@github.com:tiiuae/registration-agent-laptop.git";
    # Testing with tags name but failed at pure evaluation
    rev = "86509685e0af933d2f010636b146b5cf0723136e";
    ref = "refs/heads/parse-pkcs1";
  };
  tags = [ "prod" ];
  patches = [./remove-test.patch];
  vendorSha256 = "sha256-qzWWldUSW6yQfPERBqGSKlR5WULO235X/Co0j5/aoUo=";
  proxyVendor=true;


  postInstall = ''
    mv $out/bin/registration-agent-laptop $out/bin/registration-agent-laptop-orig
  '';
    # ...
}
