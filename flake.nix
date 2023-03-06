{
  description = "Personal Nix packages";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay.${system} ];
      };
    in rec {
      ${system} = rec {
        packages = { rvu-u = pkgs.callPackage ./packages/u { }; };

        overlay =
          (final: prev: { inherit (self.packages.${system}) ipu6-drivers; });

        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
