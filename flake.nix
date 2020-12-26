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
              (mapAttrs (k: v: "-n ${k} ${v}/bin/${v.pname}")
                packages.${system}))
          }
      '';
      packages.${system} = {
        rust = naersk.lib.${system}.buildPackage {
          pname = "bst-rust";
          src = ./src/rust;
        };
      };
    };
}
