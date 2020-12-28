{
  inputs = {
    collections = {
      url = "github:montagejs/collections/v5.1.12";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    weak-map = {
      url = "github:drses/weak-map/v1.0.5";
      flake = false;
    };
  };

  outputs = { self, collections, flake-utils, naersk, nixpkgs, weak-map }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in with builtins; rec {
        defaultPackage = pkgs.writeScriptBin "bst-bench" ''
          ${pkgs.hyperfine}/bin/hyperfine \
            -w 3 -r 32 \
            -s none \
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
              (pkgs.haskellPackages.ghcWithPackages (ps: [ ps.containers ]))
            ];
            buildPhase = "ghc Main.hs -O2 -o bst";
            installPhase = ''
              mkdir -p $out/bin
              cp bst $out/bin
            '';
          };

          java = pkgs.stdenv.mkDerivation {
            name = "bst-java";
            src = ./src/java;
            buildInputs = with pkgs; [ jdk makeWrapper ];
            buildPhase = "javac Main.java";
            installPhase = ''
              mkdir -p $out/{bin,share/java}
              cp Main.class $out/share/java
              makeWrapper ${pkgs.jre}/bin/java $out/bin/bst \
                --add-flags "-cp $out/share/java Main"
            '';
          };

          javascript = pkgs.stdenv.mkDerivation {
            name = "bst-javascript";
            src = ./src/javascript;
            buildInputs = with pkgs;
              with nodePackages; [
                nodejs
                webpack
                webpack-cli
              ];
            configurePhase = ''
              mkdir -p node_modules
              cp -r ${collections} node_modules/collections
              cp -r ${weak-map} node_modules/weak-map
            '';
            buildPhase = "webpack";
            installPhase = ''
              mkdir -p $out/bin
              echo "#!${pkgs.nodejs}/bin/node" > $out/bin/bst
              cat dist/bst.js >> $out/bin/bst
              chmod +x $out/bin/bst
            '';
          };

          # pypy.withPackages is broken
          # https://github.com/NixOS/nixpkgs/issues/39356
          python = pkgs.stdenv.mkDerivation {
            name = "bst-python";
            src = ./src/python;
            installPhase = ''
              mkdir -p $out/bin
              echo "#!${pkgs.pypy3}/bin/pypy3" > $out/bin/bst
              echo "import sys" >> $out/bin/bst
              echo 'sys.path.insert(1, "${
                with pkgs.pypy3Packages;
                buildPythonPackage rec {
                  pname = "bintrees";
                  version = "2.2.0";
                  src = fetchPypi {
                    inherit pname version;
                    extension = "zip";
                    sha256 = "4YBljZB4mFXcsOfR6yv+vEUtYMW0jnTeFrUC1hqDUtE=";
                  };
                }
              }/site-packages")' >> $out/bin/bst
              cat main.py >> $out/bin/bst
              chmod +x $out/bin/bst
            '';
          };

          rust = naersk.lib.${system}.buildPackage {
            name = "bst-rust";
            src = ./src/rust;
          };
        };
      });
}
