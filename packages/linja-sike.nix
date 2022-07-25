{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name    = "linja-sike-${version}";
  version = "5.0";

  src = fetchurl {
    url = "https://wyub.github.io/tokipona/linja-sike-5.otf";
    sha256 = "TJcKIK6byBb9/zyoKHTmhMpOGwHYG/ZPmm72huSO/Yo=";
  };

  phases = "installPhase";

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/linja-sike.otf
    chmod =r $out/share/fonts/truetype/linja-sike.otf
  '';
}
