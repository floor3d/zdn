{
  description = "A Nix-flake-based Zig development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.self.overlays.default
              ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        zigToolchain = inputs.zig-overlay.packages.${prev.stdenv.hostPlatform.system}.master;
        zlsToolchain = inputs.zls.packages.${prev.stdenv.hostPlatform.system}.zls;
      };

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              zigToolchain
              zlsToolchain
            ];

            env = {
              # Help tools locate the Zig standard library
              ZIG_LIB_DIR = "${pkgs.zigToolchain}/lib";
            };
          };
        }
      );
    };
}
