{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    purescript-overlay.url = "github:thomashoneyman/purescript-overlay";
    purescript-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    purescript-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [purescript-overlay.overlays.default];
      pkgs = import nixpkgs {inherit system overlays;};
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          purs
          purs-tidy
          purs-backend-es
          spago-unstable
          nodejs_20
        ];
      };
    });
}
