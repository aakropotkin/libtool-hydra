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

      defaultPackage.x86_64-linux =
        self.packages.x86_64-linux.libtool-bootstrapped;

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

      };

      hydraJobs = {
        libtool-source-flake.x86_64-linux =
          self.packages.x86_64-linux.libtool-source-flake;

        libtool-bootstrapped.x86_64-linux =
          self.packages.x86_64-linux.libtool-bootstrapped;
      };
    };
}
