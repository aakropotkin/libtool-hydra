{ lib
, stdenv
#, fetchGit
, git
, autoconf
, automake
, m4
, perl
, help2man
, hostname
, texinfoInteractive
, libtoolSrc
#, gitmodulesSrc
}:

stdenv.mkDerivation rec {
  name = "libtool-main";
  src = libtoolSrc;
  outputs = [ "out" "lib" ];

  patchPhase = ''
    cat <<EOF >> bootstrap.conf
require_dotgitmodules=:
require_gnulib_cache=:
require_gnulib_merge_changelog=:
require_gnulib_url=:
require_gnulib_submodule=:
EOF
    echo "2.4.5" > .prev-version
    echo "2.4.6.63-dirty" > .version
    echo "2.4.6.63" > .tarball-version
    echo "4242" > .serial

    cat <<EOF > doc/version.texi
@set UPDATE $( date +'%d %B %Y'; )
@set UPDATED-MONTH $( date +'%B %Y'; )
@set EDITION 2.4.6.63-dirty
@set VERSION 2.4.6.63-dirty
EOF
  '';

  preConfigure = ''
    ./bootstrap --skip-git
  '';

  preBuild = ''
    buildFlagsArray=( libtoolize libtool libltdl/libltdl.la )
  '';

  installTargets = [
    "install-scripts-local"
    "install-exec-recursive"
  ];

  nativeBuildInputs = [
    perl help2man texinfoInteractive m4 autoconf automake git
    hostname
  ];
  propagatedBuildInputs = [m4];

  # Don't fixup "#! /bin/sh" in Libtool, otherwise it will use the
  # "fixed" path in generated files!
  dontPatchShebangs = true;

  # XXX: The GNU ld wrapper does all sorts of nasty things wrt. RPATH, which
  # leads to the failure of a number of tests.
  #doCheck = false;
  #doInstallCheck = false;

  enableParallelBuilding = true;

  meta = with lib; {
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
}

