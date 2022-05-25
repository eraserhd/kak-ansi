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
          test = pkgs.stdenv.mkDerivation {
            name = "kak-ansi-tests-2019.09.09";
            src = ./.;
            buildPhase = let
              localeArchive = if pkgs.stdenv.isDarwin
                              then ""
                              else "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive";
            in ''
              rm -f kak-ansi-filter
              LC_ALL=en_US.UTF-8 ${localeArchive} ${pkgs.bash}/bin/bash tests/tests.bash
            '';
            installPhase = ''
              touch $out
            '';
          };
        };
    })) // {
      overlays.default = final: prev: {
        kakounePlugins = prev.kakounePlugins // {
          kak-ansi = prev.callPackage ./derivation.nix {};
        };
      };
    };
}
