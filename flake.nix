{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, naersk, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in with builtins; rec {
        defaultPackage = pkgs.writeScriptBin "bst-bench" ''
          ${pkgs.hyperfine}/bin/hyperfine \
            -w 3 -r 32 \
            -S ${pkgs.dash}/bin/dash \
            -u millisecond \
            --export-json results.json \
            --export-markdown results.md \
            ${
              concatStringsSep " "
              (attrValues (mapAttrs (k: v: "-n ${k} ${v.program}") apps))
            }
        '';
        apps = mapAttrs (_: v: {
          type = "app";
          program = "${v}/bin/bst";
        }) packages;
        packages = {
          go = pkgs.buildGoModule rec {
            name = "bst-go";
            src = builtins.path {
              name = "bst";
              path = ./src/go;
            };
            vendorSha256 = "ftiIGuIlyr766TClPwP9NYhPZqneWI+Sk2f7doR/YsA=";
          };
          haskell = pkgs.stdenv.mkDerivation {
            name = "bst-haskell";
            src = ./src/haskell;
            buildInputs = [
              (pkgs.haskellPackages.ghcWithPackages (hs: [ hs.containers ]))
            ];
            buildPhase = "ghc Main.hs -O2 -o bst";
            installPhase = ''
              mkdir -p $out/bin
              cp bst $out/bin
            '';
          };
          rust = naersk.lib.${system}.buildPackage {
            name = "bst-rust";
            src = ./src/rust;
          };
        };
      });
}
