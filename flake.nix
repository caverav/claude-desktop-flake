{
  description = "Claude Desktop — Anthropic's native macOS client, packaged as a Nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          # Claude Desktop is proprietary; scope the exemption to just this
          # package so the flake stays evaluable without `--impure` or
          # NIXPKGS_ALLOW_UNFREE.
          config.allowUnfreePredicate =
            pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-desktop" ];
        };
    in
    {
      overlays.default = final: _prev: {
        claude-desktop = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (
        system:
        let
          claude-desktop = (pkgsFor system).callPackage ./package.nix { };
        in
        {
          default = claude-desktop;
          inherit claude-desktop;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/claude-desktop";
          meta.description = "Launch Claude Desktop";
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.undmg
              pkgs.nix-prefetch
            ];
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);

      checks = forAllSystems (system: {
        build = self.packages.${system}.default;
      });
    };
}
