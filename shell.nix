let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/21.11.tar.gz";
  }) {};

  pursPkgs = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-purescript-nix";
    rev = "0ad5775c1e80cdd952527db2da969982e39ff592";
    sha256 = "0x53ads5v8zqsk4r1mfpzf5913byifdpv5shnvxpgw634ifyj1kg";
  }) { inherit pkgs; };

in pkgs.stdenv.mkDerivation {
  name = "slug";
  buildInputs = [
    pursPkgs.purs
    pursPkgs.spago
    pursPkgs.psa
    pursPkgs.purs-tidy

    pkgs.nodejs-16_x
  ];
}
