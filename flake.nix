{
  inputs = {
    bintrees = {
      url = "github:mozman/bintrees/v2.2.0";
      flake = false;
    };
    collections = {
      url = "github:montagejs/collections/v5.1.12";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    weak-map = {
      url = "github:drses/weak-map/v1.0.5";
      flake = false;
    };
  };

  outputs =
    { self, bintrees, collections, flake-utils, naersk, nixpkgs, weak-map }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mkDerivation = args:
          pkgs.stdenv.mkDerivation ({
            installPhase = ''
              mkdir -p $out/bin
              cp bst $out/bin
            '';
          } // args);
      in with builtins; rec {
        defaultPackage = pkgs.writeShellScriptBin "bst-bench" ''
          ${pkgs.hyperfine}/bin/hyperfine \
            -w 3 -r 32 \
            -s none \
            -S ${pkgs.dash}/bin/dash \
            -u millisecond \
            --export-json results.json \
            --export-markdown results.md \
            ${
              concatStringsSep " "
              (nixpkgs.lib.mapAttrsFlatten (k: v: "-n ${k} ${v.program}") apps)
            }
        '';

        apps = mapAttrs (_: v: {
          type = "app";
          program = "${v}/bin/bst";
        }) packages;

        packages = {
          cpp-clang = mkDerivation {
            name = "bst-cpp-clang";
            src = ./src/cpp;
            buildInputs = [ pkgs.clang ];
            buildPhase = "clang++ main.cc -O3 -flto -o bst";
          };

          cpp-gcc = mkDerivation {
            name = "bst-cpp-gcc";
            src = ./src/cpp;
            buildPhase = "g++ main.cc -O3 -flto -o bst";
          };

          csharp = mkDerivation {
            name = "bst-csharp";
            src = ./src/csharp;
            buildInputs = with pkgs; [ makeWrapper mono6 ];
            buildPhase = "mcs bst.cs -o+";
            installPhase = ''
              mkdir -p $out/{bin,share/mono}
              cp bst.exe $out/share/mono
              makeWrapper ${pkgs.mono6}/bin/mono $out/bin/bst \
                --add-flags $out/share/mono/bst.exe
            '';
          };

          go = pkgs.buildGoModule rec {
            name = "bst-go";
            src = builtins.path {
              name = "bst";
              path = ./src/go;
            };
            vendorSha256 = "ftiIGuIlyr766TClPwP9NYhPZqneWI+Sk2f7doR/YsA=";
          };

          haskell = mkDerivation {
            name = "bst-haskell";
            src = ./src/haskell;
            buildInputs = [
              (pkgs.haskellPackages.ghcWithPackages (ps: [ ps.containers ]))
            ];
            buildPhase = "ghc Main.hs -O2 -o bst";
          };

          java = mkDerivation {
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

          javascript-deno = mkDerivation {
            name = "bst-javascript-deno";
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
              echo "#!${pkgs.deno}/bin/deno run" > $out/bin/bst
              cat dist/bst.js >> $out/bin/bst
              chmod +x $out/bin/bst
            '';
          };

          javascript-node = mkDerivation {
            name = "bst-javascript-node";
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

          ocaml = with pkgs.ocamlPackages;
            buildDunePackage rec {
              pname = "bst-ocaml";
              version = "0.1.0";
              src = ./src/ocaml;
              buildInputs = [ iter ];
              useDune2 = true;
            };

          # pypy.withPackages is broken
          # https://github.com/NixOS/nixpkgs/issues/39356
          python = pkgs.writeScriptBin "bst" ''
            #!${pkgs.pypy3}/bin/pypy3 -OO
            import sys
            sys.path.insert(1, "${
              pkgs.pypy3Packages.buildPythonPackage {
                name = "bintrees";
                src = bintrees;
              }
            }/site-packages")
            ${readFile ./src/python/main.py}
          '';

          ruby = pkgs.writeScriptBin "bst" ''
            #!${pkgs.ruby}/bin/ruby --disable=gems,did_you_mean,rubyopt
            ${readFile ./src/ruby/main.rb}
          '';

          rust = naersk.lib.${system}.buildPackage {
            name = "bst-rust";
            src = ./src/rust;
          };
        };
      });
}
