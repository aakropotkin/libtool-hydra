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
        libtool-source-flake =
          nixpkgs.legacyPackages.x86_64-linux.callPackage ./source.nix {
            name = name + "-flake-source";
            src = libtool-master;
          };
        
        libtool-bootstrapped =
          nixpkgs.legacyPackages.x86_64-linux.callPackage ./bootstrapped.nix {
            inherit name;
            src = libtool-master;
          };
        
        libtool =
          nixpkgs.legacyPackages.x86_64-linux.callPackage ./default.nix {
            inherit name;
            src = self.packages.x86_64-linux.libtool-bootstrapped;
          };
      }; # End `packages'

      hydraJobs = {
        libtool-source-flake.x86_64-linux =
          self.packages.x86_64-linux.libtool-source-flake;

        libtool-bootstrapped.x86_64-linux =
          self.packages.x86_64-linux.libtool-bootstrapped;

        libtool.x86_64-linux = self.packages.x86_64-linux.libtool;

        libtool-check.x86_64-linux =
          self.packages.x86_64-linux.libtool.overrideAttrs ( prev: {
            doCheck = true;
          } );
      }; # End `hydraJobs'

      checks.x86_64-linux = {
        build = self.packages.x86_64-linux.libtool;
        check = self.hydraJobs.libtool-check.x86_64-linux;
      }; # End `checks'

    }; # End `outputs'
}
