{
  description = "USGS ISIS3 (planetary image processing) and its dependencies, packaged with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      # Only x86_64-linux is built and tested so far; see the roadmap.
      systems = [ "x86_64-linux" ];
      eachSystem = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Every directory in ./packages is a package. Inside the scope, ISIS sees
      # our packages first and nixpkgs for everything else.
      mkScope =
        pkgs:
        lib.makeScope pkgs.newScope (
          self:
          lib.packagesFromDirectoryRecursive {
            inherit (self) callPackage newScope;
            directory = ./packages;
          }
        );
    in
    {
      overlays.default = final: _prev: {
        isis3Packages = mkScope final;
        inherit (final.isis3Packages) isis;
      };

      packages = eachSystem (
        pkgs:
        let
          scope = mkScope pkgs;
        in
        lib.filterAttrs (_: lib.isDerivation) scope // { default = scope.isis; }
      );

      checks = eachSystem (pkgs: {
        isis-smoke = self.packages.${pkgs.stdenv.hostPlatform.system}.isis.passthru.tests.smoke;
      });

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.isis ];
          shellHook = ''
            if [ -z "''${ISISDATA:-}" ]; then
              echo "ISISDATA is not set. Point it at your ISIS data area, or fetch one with:"
              echo "  downloadIsisData base \$HOME/isisdata"
            fi
          '';
        };
      });

      # Formatting works anywhere, even where ISIS itself is not built.
      formatter = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
