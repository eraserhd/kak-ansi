{ nixpkgs ? (import ./nixpkgs.nix), ... }:
let
  pkgs = import nixpkgs { config = {}; };
  kak-ansi = pkgs.callPackage ./derivation.nix {};
in {
  test = pkgs.runCommandNoCC "kak-ansi-test" {} ''
    : ${kak-ansi}
    mkdir -p $out
  '';
}
