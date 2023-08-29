{
  description = "mGBA Game Boy Advance Emulator";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
      systems = attrNames inputs.alejandra.packages;
      nixpkgsFor = std.genAttrs systems (system:
        import nixpkgs {
          localSystem = system;
          crossSystem = system;
          overlays = [];
        });
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
      packages =
        std.mapAttrs (system: pkgs: {
          mgba = pkgs.stdenv.mkDerivation {
            name = "mgba";
            src = ./.;
            nativeBuildInputs = with pkgs; [
              cmake
              ninja
              pkg-config
              wrapGAppsHook
              qt5.wrapQtAppsHook
            ];
            dontWrapGApps = true;
            preFixup = ''
              qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
            '';
            buildInputs = with pkgs; [
              SDL2
              lua
              libedit
              ffmpeg
              zlib
              minizip
              libpng
              libzip
              epoxy
              sqlite
              libelf
              json_c
              qt5.qtbase
              qt5.qtmultimedia
              qt5.qttools
            ];
          };
          default = self.packages.${system}.mgba;
        })
        nixpkgsFor;
      apps =
        std.mapAttrs (system: pkgs: {
          mgba = {
            type = "app";
            program = "${pkgs.mgba}/bin/mgba";
          };
          mgba-qt = {
            type = "app";
            program = "${pkgs.mgba}/bin/mgba-qt";
          };
          default = self.apps.${system}.mgba;
        })
        self.packages;
    };
}
