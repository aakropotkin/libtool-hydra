{
  description = "GNU Libtool";
  
  inputs.libtool-master = {
    url        = "git://git.savannah.gnu.org/libtool.git";
    type       = "git";
    flake      = false;
    submodules = true;
  };

  outputs = { self, nixpkgs, libtool-master }:
    let
      pname = "libtool";
      name  = pname + "-" + libtool-master.shortRev;
      prevVersion =
        nixpkgs.legacyPackages.x86_64-linux.lib.removeSuffix "\n"
          ( builtins.readFile "${libtool-master}/.prev-version" );
      serial      = libtool-master.revCount;
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
        libtool-source-tarballs =
          nixpkgs.legacyPackages.x86_64-linux.releaseTools.sourceTarball rec {
            inherit pname version;
            versionSuffix = toString src.shortRev;
            src = libtool-master;
            copy = "true"; # Tells `bootstrap' to copy files, not symlink
            dontPatchTestsuite = true;

            preAutoconf = ''
              echo "${toString src.revCount}" > .serial
              echo "$version-$versionSuffix" > .version
              echo "$version" > .tarball-version
              substituteInPlace libtoolize.in               \
                --subst-var-by auxscriptdir $src/build-aux  \
                --replace '/usr/bin/env sh' '/bin/sh'
              substituteInPlace build-aux/ltmain.in    \
                --replace '/usr/bin/env sh' '/bin/sh'
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
              autoconf automake gitMinimal m4 perl help2man texinfoInteractive
              hostname
            ];

            buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
              autoconf automake m4 perl help2man texinfoInteractive hostname
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
              autoconf automake m4 perl help2man texinfoInteractive hostname
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
            checkPhase = ''
              make check TESTSUITEFLAGS='NIX_DONT_SET_RPATH_x86_64_unknown_linux_gnu=1' \
                   INNER_TESTSUITEFLAGS='NIX_DONT_SET_RPATH_x86_64_unknown_linux_gnu=1'
            '';
            postInstall = ''
              cp tests/testsuite.log $out/
            '';
            failureHook = ''
              cp tests/testsuite.log $out/
              cp -r tests/testsuite.dir $out/
            '';
          } );
      }; # End `hydraJobs'

      checks.x86_64-linux = {
        build = self.packages.x86_64-linux.libtool;
        check = self.hydraJobs.libtool-check.x86_64-linux;
      }; # End `checks'

    }; # End `outputs'
}
