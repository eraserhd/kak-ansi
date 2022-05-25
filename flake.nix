{
  description = "TODO: fill me in";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        kak-ansi = pkgs.callPackage ./derivation.nix {};
      in {
        packages = {
          default = kak-ansi;
          inherit kak-ansi;
        };
        checks = {
          test = pkgs.runCommandNoCC "kak-ansi-test" {} ''
            mkdir -p $out
            : ${kak-ansi}
          '';
        };
    })) // {
      overlays.default = final: prev: {
        kak-ansi = prev.callPackage ./derivation.nix {};
      };
    };
}
