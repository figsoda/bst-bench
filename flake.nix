{
  inputs = {
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, naersk, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in with builtins; rec {
      defaultPackage.${system} = pkgs.writeScriptBin "bst-bench" ''
        ${pkgs.hyperfine}/bin/hyperfine \
          -w 3 -r 32 \
          -S ${pkgs.dash}/bin/dash \
          -u millisecond \
          --export-json results.json \
          ${
            concatStringsSep " " (attrValues
              (mapAttrs (k: v: "-n ${k} ${v}/bin/bst") packages.${system}))
          }
      '';
      packages.${system} = {
        haskell = let
          ghc = pkgs.haskellPackages.ghcWithPackages
            (haskellPackages: [ haskellPackages.containers ]);
        in pkgs.stdenv.mkDerivation {
          name = "bst-haskell";
          src = ./src/haskell;
          buildInputs = [ ghc ];
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
    };
}
