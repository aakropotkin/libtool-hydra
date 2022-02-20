{ lib
, stdenv
, autoconf
, automake
, m4
, perl
, help2man
, hostname
, texinfoInteractive
, src
, pname   ? "libtool"
, version ? "0"
}:

stdenv.mkDerivation rec {
  inherit src pname version;
  outputs = ["out" "lib"];

  nativeBuildInputs = [
    perl help2man texinfoInteractive m4 autoconf automake hostname
  ];
  propagatedBuildInputs = [m4];

  # Don't fixup "#! /bin/sh" in Libtool, otherwise it will use the
  # "fixed" path in generated files!
  #dontPatchShebangs = true;

  # XXX: The GNU ld wrapper does all sorts of nasty things wrt. RPATH, which
  # leads to the failure of a number of tests.
  doCheck = false;
  doInstallCheck = false;

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

