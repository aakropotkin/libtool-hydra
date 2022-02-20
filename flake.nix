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
      }; # End `apps'

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.libtool;

      packages.x86_64-linux = {
        libtool-source-tarball =
          nixpkgs.legacyPackages.x86_64-linux.releaseTools.sourceTarball rec {
            inherit pname version;
            versionSuffix = toString src.shortRev;
            src = libtool-master;
            copy = "true"; # Tells `bootstrap' to copy files, not symlink
            preAutoconf = ''
              echo "${toString src.revCount}" > .serial
              echo "$version-$versionSuffix" > .version
              echo "$version" > .tarball-version
              substituteInPlace libtoolize.in               \
                --subst-var-by auxscriptdir $src/build-aux
            '';
            preDist = ''
              make libtoolize
              patchShebangs --build libtoolize
            '';
            postDist = ''
              cp README.md $out/
              echo "doc readme $out/README.md" >> $out/nix-support/hydra-build-products
            '';
            bootstrapBuildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
              autoconf automake gitMinimal m4 perl help2man texinfoInteractive
              hostname
            ];
          };
        
        libtool =
          nixpkgs.legacyPackages.x86_64-linux.callPackage ./default.nix {
            inherit pname version;
            src = "${self.packages.x86_64-linux.libtool-source-tarball}" +
                  "/tarballs/${pname}-${version}.tar.gz";
          };
      }; # End `packages'

      hydraJobs = {
        libtool-source-tarball.x86_64-linux =
          self.packages.x86_64-linux.libtool-source-tarball;

        libtool.x86_64-linux = self.packages.x86_64-linux.libtool;

        libtool-check.x86_64-linux =
          self.packages.x86_64-linux.libtool.overrideAttrs ( prev: {
            doCheck = true;
            checkPhase = ''
              make check
            '';
            installPhase = ''
              mkdir -p $out
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
