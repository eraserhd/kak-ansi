{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "kak-ansi";
  version = "0.2.6";

  src = ./.;

  installPhase = ''
    mkdir -p $out/bin $out/share/kak/autoload/plugins/
    cp kak-ansi-filter $out/bin/
    # Hard-code path of filter and don't try to build when Kakoune boots
    sed '
      /^declare-option.* ansi_filter /i\
declare-option -hidden str ansi_filter %{'"$out"'/bin/kak-ansi-filter}
      /^declare-option.* ansi_filter /,/^}/d
    ' rc/ansi.kak >$out/share/kak/autoload/plugins/ansi.kak
  '';

  meta = with lib; {
    description = "Kakoune support for rendering ANSI code";
    homepage = "https://github.com/eraserhd/kak-ansi";
    license = licenses.unlicense;
    maintainers = with maintainers; [ eraserhd ];
    platforms = platforms.all;
  };
}
