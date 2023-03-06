{
  description = "Personal Nix packages";

  inputs = { flake-utils.url = "github:numtide/flake-utils"; };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay.${system} ];
        };
      in rec {
        packages = {
          rvu-u = pkgs.callPackage ./packages/u { };
          rvu-kolide = pkgs.callPackage ./packages/kolide { };
        };

        overlay = (final: prev: {
          inherit (self.packages.${system}) rvu-u rvu-kolide;
        });

        formatter = pkgs.nixpkgs-fmt;
      });
}
