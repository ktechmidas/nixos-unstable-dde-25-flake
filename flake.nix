{
  description = "Deepin Desktop Environment (DDE 25 / DDE 7.0) for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          deepin = import ./packages { inherit pkgs; };
        in
        # Expose all deepin packages as flake outputs
        builtins.removeAttrs (nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) deepin) [ "override" "overrideDerivation" "overrideScope" "overrideScope'" "newScope" "callPackage" "packages" ]
      );

      # Expose the full scope for overlays and modules
      lib = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          deepinScope = import ./packages { inherit pkgs; };
        }
      );

      # NixOS module (placeholder for now)
      nixosModules.deepin = import ./modules/deepin.nix { inherit self; };

      # Quick VM test
      # Usage: nix run .#vm
      apps = forAllSystems (system: {
        vm = {
          type = "app";
          program = "${self.nixosConfigurations."dde-test-${system}".config.system.build.vm}/bin/run-dde-test-vm";
        };
      });

      nixosConfigurations = builtins.listToAttrs (
        map (system: {
          name = "dde-test-${system}";
          value = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              self.nixosModules.deepin
              ./vm/configuration.nix
            ];
          };
        }) supportedSystems
      );
    };
}
