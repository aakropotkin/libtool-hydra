{
  description = "GNU Libtool";
  
  inputs.libtool = {
    url        = "git://git.savannah.gnu.org/libtool.git";
    type       = "git";
    flake      = false;
    submodules = true;
  };

  inputs.gnulib = {
    url        = "https://git.savannah.gnu.org/r/gnulib.git";
    type       = "git";
    flake      = false;
    rev        = "a5218207e5f92e152a34994cce4aa415b1eb25c8";
  };

  outputs = { self, nixpkgs, gnulib, libtool }:
    let
      lt-source = ./libtool;
      pname = "libtool";
      name  = pname + "-" + lt-source.shortRev;
      prevVersion =
        nixpkgs.legacyPackages.x86_64-linux.lib.removeSuffix "\n"
          ( builtins.readFile "${lt-source}/.prev-version" );
      serial      = lt-source.revCount;
      prevSerial  = 4179;
      revVersion  = serial - prevSerial;
      version     = prevVersion + ".${toString revVersion}";

    in {

      defaultApp.x86_64-linux = self.apps.x86_64-linux.libtool;

      apps.x86_64-linux = {
        libtool = {
          type = "app";
          program = "${self.packages.x86_64-linux.libtool}/bin/libtool";
        };

        libtoolize = {
          type = "app";
          program = "${self.packages.x86_64-linux.libtool}/bin/libtoolize";
        };

        testsuite = {
          type = "app";
          program = "${self.packages.x86_64-linux.libtool-source-tarball}" +
                    "/tests/testsuite";
        };
      }; # End `apps'

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.libtool;

      packages.x86_64-linux = {

        gnulib = nixpkgs.legacyPackages.x86_64-linux.callPackage ./gnulib.nix {
          src = gnulib;
          version = toString gnulib.revCount;
        };

        libtool-source-tarballs =
          nixpkgs.legacyPackages.x86_64-linux.releaseTools.sourceTarball rec {
            inherit pname version;
            versionSuffix = toString src.shortRev;
            src = lt-source;
            copy = "true"; # Tells `bootstrap' to copy files, not symlink
            dontPatchTestsuite = true;
            
            VERSION = version;

            preAutoconf =
              let
                libtool-bootstrap-min = ./bootstrap.sh;
                libtool-gnulib-cache  = ./gnulib-cache.m4;
                libtool-gnulib-comp   = ./gnulib-comp.m4;
                libtool-changelog     = ./ChangeLog;
              in ''
                echo "${toString src.revCount}" > .serial
                echo "$version-$versionSuffix" > .version
                echo "$version" > .tarball-version
                substituteInPlace libtoolize.in               \
                  --subst-var-by auxscriptdir $src/build-aux  \
                  --replace '/usr/bin/env sh' '/bin/sh'
                substituteInPlace build-aux/ltmain.in    \
                  --replace '/usr/bin/env sh' '/bin/sh'
                rm bootstrap

                cat ${libtool-bootstrap-min} > bootstrap
                chmod a+x bootstrap
                patchShebangs --build bootstrap

                cat ${libtool-gnulib-cache} > m4/gnulib-cache.m4
                cat ${libtool-gnulib-comp} > m4/gnulib-comp.m4
                cat ${libtool-changelog} > ChangeLog
              '';

            preDist = ''
              make libtoolize
              mv libtoolize libtoolize~
              build-aux/inline-source libtoolize~ > libtoolize
              rm libtoolize~
              chmod a+x ./libtoolize
              patchShebangs --build libtoolize

              if test -z "$dontPatchTestsuite"; then
                make tests/testsuite
                mv tests/testsuite tests/testsuite~
                abs_top_srcdir='.'  \
                  build-aux/inline-source tests/testsuite~ > tests/testsuite
                rm tests/testsuite~
                chmod a+x ./tests/testsuite
                patchShebangs --build tests/testsuite
              fi
            '';

            postDist = ''
              cp README.md $out/
              echo "doc readme $out/README.md" >> $out/nix-support/hydra-build-products
              cp libtoolize $out/
              echo "file libtoolize $out/libtoolize" >> $out/nix-support/hydra-build-products

              if test -z "$dontPatchTestsuite"; then
                cp tests/testsuite $out/
                echo "file testsuite $out/testsuite" >> $out/nix-support/hydra-build-products
              fi
            '';

            bootstrapBuildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
              autoconf automake m4 gnused gawk coreutils
            ];

            buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
              autoconf automake m4 help2man texinfoInteractive
            ];
          };

        libtool-source-tarball =
          nixpkgs.legacyPackages.x86_64-linux.runCommandNoCC
            "libtool-source-tarball" {
              tarballs = self.packages.x86_64-linux.libtool-source-tarballs;
              inherit version;
            } ''
              mkdir -p $out
              tar xf $tarballs/tarballs/${pname}-${version}.tar.gz  \
                  -C $out --strip-components=1
            '';
        
        libtool =
          let
            lt-tarballs = self.packages.x86_64-linux.libtool-source-tarballs;
          in nixpkgs.legacyPackages.x86_64-linux.releaseTools.nixBuild {
            inherit pname version;
            src = lt-tarballs;
            outputs = ["out" "lib"];
            preConfigure = ''
              cp ${lt-tarballs}/libtoolize ./libtoolize
            '';
            nativeBuildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
              autoconf automake m4 help2man texinfoInteractive gnused gawk
              coreutils
            ];
            propagatedBuildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
              m4
            ];
            doCheck = false;
            doInstallCheck = false;
            enableParallelBuilding = true;
            meta = with nixpkgs.legacyPackages.x86_64-linux.lib; {
              description = "GNU Libtool, a generic library support script";
              longDescription = ''
                GNU libtool is a generic library support script.  Libtool hides
                the complexity of using shared libraries behind a consistent,
                portable interface.

                To use libtool, add the new generic library building commands to
                your Makefile, Makefile.in, or Makefile.am.  See the
                documentation for details.
              '';
              homepage = "https://www.gnu.org/software/libtool/";
              license = licenses.gpl2Plus;
              maintainers = [];
              platforms = platforms.unix;
            };
          };
      }; # End `packages'

      hydraJobs = {
        libtool-source-tarballs.x86_64-linux =
          self.packages.x86_64-linux.libtool-source-tarballs;

        libtool.x86_64-linux = self.packages.x86_64-linux.libtool;

        libtool-check.x86_64-linux =
          self.packages.x86_64-linux.libtool.overrideAttrs ( prev: {
            pname = prev.pname + "-check";
            doCheck = true;
            keepBuildDirectory = true;
            #succeedOnFailure = true;
            TESTSUITEFLAGS =
              "NIX_DONT_SET_RPATH_x86_64_unknown_linux_gnu=1 -x -d";
            checkPhase = ''
              make check-local                          \
                TESTSUITEFLAGS="$TESTSUITEFLAGS"        \
                INNER_TESTSUITEFLAGS="$TESTSUITEFLAGS"
            '';
            postInstall = ''
              test -f tests/testsuite.log && cp tests/testsuite.log $out/
            '';
            failureHook = ''
              test -f tests/testsuite.log && cp tests/testsuite.log $out/
              test -d tests/testsuite.dir && cp -r tests/testsuite.dir $out/
            '';
          } );
      }; # End `hydraJobs'

      checks.x86_64-linux = {
        build = self.packages.x86_64-linux.libtool;
        check = self.hydraJobs.libtool-check.x86_64-linux;
      }; # End `checks'

    }; # End `outputs'
}
