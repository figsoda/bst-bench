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
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    weak-map = {
      url = "github:drses/weak-map/v1.0.5";
      flake = false;
    };
  };

  outputs = { self, bintrees, collections, flake-utils, nixpkgs, weak-map }:
    flake-utils.lib.eachDefaultSystem (system:
      with builtins;
      let
        pkgs = nixpkgs.legacyPackages.${system};
        buildDotnetPackage = { name, src, deps ? [ ] }:
          pkgs.stdenv.mkDerivation {
            inherit name src;
            buildInputs = with pkgs; [
              dotnetCorePackages.sdk_5_0
              dotnetPackages.Nuget
              makeWrapper
            ];
            installPhase = ''
              export HOME=$(mktemp -d)
              mkdir -p $out/bin
              dotnet nuget disable source nuget.org
              ${concatStringsSep "\n" (map ({ name, version, sha256 }:
                "nuget add ${
                  fetchurl {
                    inherit sha256;
                    url =
                      "https://www.nuget.org/api/v2/package/${name}/${version}";
                  }
                } -src $HOME/nuget") deps)}
              dotnet restore -s $HOME/nuget
              dotnet build -c Release -o $out/share
              makeWrapper ${pkgs.dotnetCorePackages.net_5_0}/bin/dotnet \
                $out/bin/bst --add-flags $out/share/bst.dll
            '';
            DOTNET_CLI_TELEMETRY_OPTOUT = "1";
            DOTNET_NOLOGO = "1";
          };
      in rec {
        defaultPackage = pkgs.writeShellScriptBin "bst-bench" ''
          ${concatStringsSep "" (nixpkgs.lib.mapAttrsFlatten (k: v: ''
            RESULT=$(${v.program})
            if [ "$RESULT" != 1000000 ]; then
              echo "${k} failed the test"
              echo "Expected output: 1000000"
              echo "Actual output:   $RESULT"
              exit 1
            fi
          '') apps)}

          ${pkgs.hyperfine}/bin/hyperfine \
            -w "''${1:-1}" -r "''${2:-2}" \
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
          cpp-clang = pkgs.stdenv.mkDerivation {
            name = "bst-cpp-clang";
            src = ./src/cpp;
            buildInputs = [ pkgs.clang_11 ];
            installPhase = ''
              mkdir -p $out/bin
              clang++ main.cc -std=c++20 -O3 -flto -o $out/bin/bst
            '';
          };

          cpp-gcc = pkgs.stdenv.mkDerivation {
            name = "bst-cpp-gcc";
            src = ./src/cpp;
            installPhase = ''
              mkdir -p $out/bin
              g++ main.cc -std=c++20 -O3 -flto -o $out/bin/bst
            '';
          };

          csharp-dotnet = buildDotnetPackage {
            name = "bst-csharp-dotnet";
            src = ./src/csharp;
          };

          csharp-mono = pkgs.stdenv.mkDerivation {
            name = "bst-csharp-mono";
            src = ./src/csharp;
            buildInputs = with pkgs; [ makeWrapper mono6 ];
            installPhase = ''
              mkdir -p $out/{bin,share}
              mcs main.cs -o+ -out:$out/share/bst.exe
              makeWrapper ${pkgs.mono6}/bin/mono $out/bin/bst \
                --add-flags $out/share/bst.exe
            '';
          };

          d-gdc = pkgs.stdenv.mkDerivation {
            name = "bst-d-gdc";
            src = ./src/d;
            buildInputs = [ pkgs.gdc ];
            installPhase = ''
              mkdir -p $out/bin
              gdc main.d -O3 -flto -o $out/bin/bst
            '';
          };

          d-ldc = pkgs.stdenv.mkDerivation {
            name = "bst-d-ldc";
            src = ./src/d;
            buildInputs = [ pkgs.ldc ];
            installPhase = ''
              mkdir -p $out/bin
              ldc2 main.d -flto-binary=${pkgs.llvm_11}/lib/LLVMgold.so \
                -O --flto=full --of $out/bin/bst
            '';
          };

          fsharp = buildDotnetPackage {
            name = "bst-fsharp";
            src = ./src/fsharp;
            deps = [{
              name = "FSharp.Core";
              version = "5.0.0";
              sha256 = "10qjk9rc950prnf7m8lndcr1qxihz4jcwzfrz8q7m5997h3zx28x";
            }];
          };

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
            installPhase = ''
              mkdir -p $out/bin
              ghc Main.hs -O2 -o $out/bin/bst
            '';
          };

          idris-chez = pkgs.stdenv.mkDerivation {
            name = "bst-idris-chez";
            src = ./src/idris;
            buildInputs = with pkgs; [ idris2 makeWrapper ];
            installPhase = ''
              mkdir -p $out/{bin,lib}
              idris2 main.idr -p contrib -o bst
              cp build/exec/bst_app/{bst,libidris2_support}.so $out/lib
              makeWrapper $out/lib/bst.so $out/bin/bst \
                --set LD_LIBRARY_PATH $out/lib
            '';
          };

          idris-gambit = pkgs.stdenv.mkDerivation {
            name = "bst-idris-gambit";
            src = ./src/idris;
            buildInputs = [ pkgs.idris2 ];
            installPhase = ''
              mkdir -p $out/bin
              idris2 main.idr --cg gambit --output-dir $out/bin -o bst
            '';
            GAMBIT_GSC = "${pkgs.gambit}/bin/gsc";
          };

          java = pkgs.stdenv.mkDerivation {
            name = "bst-java";
            src = ./src/java;
            buildInputs = with pkgs; [ jdk makeWrapper ];
            installPhase = ''
              mkdir -p $out/{bin,share}
              javac Main.java -d $out/share
              makeWrapper ${pkgs.jre}/bin/java $out/bin/bst \
                --add-flags "-cp $out/share Main"
            '';
          };

          javascript-deno = pkgs.stdenv.mkDerivation {
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

          javascript-node = pkgs.stdenv.mkDerivation {
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

          kotlin = pkgs.stdenv.mkDerivation {
            name = "bst-kotlin";
            src = ./src/kotlin;
            buildInputs = with pkgs; [ kotlin makeWrapper ];
            installPhase = ''
              mkdir -p $out/{bin,share}
              kotlinc main.kt -include-runtime -d $out/share/bst.jar
              makeWrapper ${pkgs.jre}/bin/java $out/bin/bst \
                --add-flags "-jar $out/share/bst.jar"
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

          rust = pkgs.stdenv.mkDerivation {
            name = "bst-rust";
            src = ./src/rust;
            buildInputs = [ pkgs.rustc ];
            installPhase = ''
              mkdir -p $out/bin
              rustc main.rs -o $out/bin/bst --edition 2018 \
                -C{opt-level=3,panic=abort,lto=fat,codegen-units=1,target-cpu=native}
            '';
          };

          scala = pkgs.stdenv.mkDerivation {
            name = "bst-scala";
            src = ./src/scala;
            buildInputs = with pkgs; [ makeWrapper scala ];
            installPhase = ''
              mkdir -p $out/{bin,share}
              scalac main.scala -opt:l:inline -d $out/share/bst.jar
              makeWrapper ${pkgs.jre}/bin/java $out/bin/bst \
                --add-flags "-cp $out/share/bst.jar:${pkgs.scala}/lib/scala-library.jar Main"
            '';
          };
        };
      });
}
