{ lib
, stdenv,
pkgs,
...
}: let
  weston-12= pkgs.callPackage ./weston-12/weston-12.0.2.nix {};
in
stdenv.mkDerivation rec {
  pname = "weston-bar";
  version = "1.2.4";

  src =  builtins.fetchGit {
    url = "https://github.com/buianhhuy96/weston-bar";
    rev = "da12de5ff149a7d8cf52bd3c5e497ae996162530";
  };

  strictDeps = true;

  buildInputs = with pkgs; [
    pixman
    libxkbcommon
    wayland
    cairo.dev
    mesa
    libdrm
    glib
    SDL2
    alsa-lib
    libjpeg
    weston-12
  ];

  phases = [ "buildPhase" "installPhase" ];

  NIX_CFLAGS_COMPILE = toString [
    "-std=c11"
    "-pthread"
    "-I${src}"
    "-I${src}/source"
    "-I${src}/include"
    "-I${src}/include/libweston"
    "-I${src}/source/gen-protocol"
    "-I${src}/shared"
    "-I${pkgs.cairo.dev}/include/cairo"
    "-I${pkgs.glib.out}/lib/glib-2.0/include"
    "-I${pkgs.glib.dev}/include/glib-2.0"
    "-I${pkgs.alsa-lib.dev}/include"
    "-I${pkgs.libjpeg_turbo.dev}/include"
    "-I${pkgs.libdrm.dev}/include"
    "-I${pkgs.libdrm.dev}/include/libdrm"
    # Not required for toolbar and library
    #"-I/usr/include/pixman-1"
    #"-I/usr/include/gdk-pixbuf-2.0 " 
  ];

  NIX_CFLAGS_LINK = [ "-lSDL2" "-lwayland-client" "-lpng" "-lutil" "-lwayland-cursor" "-lpixman-1"  "-lcairo"  "-lxkbcommon" "-lasound" "-ljpeg" "-lm" "-lrt" ];
  buildPhase = let
   WINDOW_SOURCES="window.c ../shared/file-util.c ../shared/image-loader.c ../shared/cairo-util.c ../shared/xalloc.c ../shared/option-parser.c ../shared/frame.c ../shared/os-compatibility.c ../shared/config-parser.c";
   WINDOW_SOURCES_WITH_PATH=toString (builtins.map (x: "${src}/source/" + x) (lib.strings.splitString " " WINDOW_SOURCES));
   WAYWARD_SOURCES="wayward-shell.c";
   WAYWARD_SOURCES_WITH_PATH=toString (builtins.map (x: "${src}/source/" + x) (lib.strings.splitString " " WAYWARD_SOURCES));
   GEN_SOURCES="gen-protocol/xdg-shell-protocol.c gen-protocol/viewporter-protocol.c gen-protocol/pointer-constraints-unstable-v1-protocol.c gen-protocol/relative-pointer-unstable-v1-protocol.c gen-protocol/text-cursor-position-protocol.c gen-protocol/weston-desktop-shell-code.c gen-protocol/shell-helper-protocol.c";
   GEN_SOURCES_WITH_PATH=toString (builtins.map (x: "${src}/source/" + x) (lib.strings.splitString " " GEN_SOURCES));
  in
    ''
    runHook preBuild
    gcc -Wno-deprecated-declarations ${WAYWARD_SOURCES_WITH_PATH} ${WINDOW_SOURCES_WITH_PATH} ${GEN_SOURCES_WITH_PATH} -lm -o weston-bar
    gcc -shared  -lm -lweston-12 -o shell_helper.so -fPIC ${src}/source/gen-protocol/weston-desktop-shell-code.c ${src}/source/gen-protocol/shell-helper-protocol.c ${src}/source/shell-helper.c
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    mkdir -p $out/lib
    cp weston-bar $out/bin
    cp shell_helper.so $out/lib
    runHook postInstall
  '';
}
