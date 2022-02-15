{ nixpkgs    ? builtins.fetchTarball https://nixos.org/channels/nixpkgs-unstable
, libtoolSrc
#, gitmodulesSrc
, ...
}:

let
  pkgs = import nixpkgs { system = builtins.currentSystem or "x86_64-linux"; };

  jobs = rec {

    #libtoolGitSrcs = pkgs.stdenvNoCC.mkDerivation {
    #  url = "https://git.savannah.gnu.org/git/libtool.git";
    #  name = "libtoolGitSrcs-main";
    #  nativeBuildInputs = [pkgs.git];
    #  dontUnpack = true;
    #  dontConfigure = true;
    #  dontBuild  = true;
    #  installPhase = ''
    #    git clone $url $out
    #  '';
    #};

    libtool-main = pkgs.callPackage ./default.nix { 
      inherit libtoolSrc;
      #libtoolSrc = libtoolGitSrcs;
    };
  };
in jobs
