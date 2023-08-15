{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name    = "linja-sike-${version}";
  version = "5.0";

  src = fetchurl {
    url = "https://lipamanka.gay/linjalipamanka-normal.otf";
    sha256 = "ZuKxVZKfxePZAjlInTZX9cZ8AXV8O7X6RGDSq+o3s1s=";
  };

  phases = "installPhase";

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/linja-sike.otf
    chmod =r $out/share/fonts/truetype/linja-sike.otf
  '';
}
