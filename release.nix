{ nixpkgs ? (import ./nixpkgs.nix), ... }:
let
  pkgs = import nixpkgs { config = {}; };
  kak-ansi = pkgs.callPackage ./derivation.nix {};
in {
  test = pkgs.stdenv.mkDerivation {
    name = "kak-ansi-tests-2019.09.09";
    src = ./.;
    buildPhase = ''
      LC_ALL=en_US.UTF-8 LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive ${pkgs.bash}/bin/bash tests/tests.bash
    '';
    installPhase = ''
      mkdir -p $out
    '';
  };
}
