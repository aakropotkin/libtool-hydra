#! /bin/sh
# ============================================================================ #
#
#
# ---------------------------------------------------------------------------- #

PACKAGE="${PACKAGE:-libtool}";
PACKAGE_BUGREPORT="${PACKAGE_BUGREPORT:-bug-libtool@gnu.org}";
PACKAGE_NAME="${PACKAGE_NAME:-GNU Libtool}";
PACKAGE_URL="${PACKAGE_URL:-http://www.gnu.org/s/libtool}";
VERSION="${VERSION:-2.6.4}";

GNULIBDIR="${GNULIBDIR:-gnulib}";
GNULIB_LOCALDIR="${GNULIB_LOCALDIR:-gl}";
BOOTSTRAPDIR="${BOOTSTRAPDIR:-gl-mod/bootstrap}";

GNULIB_TOOL="${GNULIB_TOOL:-$GNULIBDIR/gnulib-tool}";
BOOTSTRAP_MAKEFILE="${BOOTSTRAP_MAKEFILE:-Makefile}";

AUTOMAKE="${AUTOMAKE:-automake}";
AUTOCONF="${AUTOCONF:-autoconf}";
AUTORECONF="${AUTORECONF:-autoreconf}";
ACLOCAL="${ACLOCAL:-ACLOCAL}";
AUTOM4TE="${AUTOM4TE:-autom4te}";
AUTOTEST="${AUTOTEST:-$AUTOM4TE --language=autotest}";

# 1.29
HELP2MAN="${HELP2MAN:-help2man}";
# 3.81
MAKE="${MAKE:-make}";
# 4.8
MAKEINFO="${MAKEINFO:-makeinfo}";
# 4.999.8beta
XZ="${XZ:-xz}"; # FIXME

SED="${SED:-sed}";
GREP="${GREP:-grep}";
BASENAME="${BASENAME:-basename}";
PATCH="${PATCH:-patch}";
HEAD="${HEAD:-head}";

V="${V:-1}";
src="${src:-$PWD}";


# ---------------------------------------------------------------------------- #

##AUTOMAKE_VERSION=$( $AUTOMAKE --version|$HEAD -n1; );
##AUTOMAKE_VERSION=$( echo "$AUTOMAKE_VERSION"|$SED 's/^.* \([0-9\.]*\)$/\1/'; );


# ---------------------------------------------------------------------------- #

declare -a bootstrap_outputs;
bootstrap_outputs=(
  .serial
  .version
  COPYING
  ChangeLog
  GNUmakefile
  INSTALL
  Makefile.in
  README
  README-release
  aclocal.m4
  autom4te.cache/
  build-aux/announce-gen
  build-aux/bootstrap.in
  build-aux/compile
  build-aux/config.guess
  build-aux/config.sub
  build-aux/depcomp
  build-aux/do-release-commit-and-tag
  build-aux/extract-trace
  build-aux/funclib.sh
  build-aux/gendocs.sh
  build-aux/git-version-gen
  build-aux/gitlog-to-changelog
  build-aux/gnu-web-doc-update
  build-aux/gnupload
  build-aux/inline-source
  build-aux/install-sh
  build-aux/ltmain.sh
  build-aux/mdate-sh
  build-aux/missing
  build-aux/options-parser
  build-aux/test-driver
  build-aux/texinfo.tex
  build-aux/update-copyright
  build-aux/useless-if-before-free
  build-aux/vc-list-files
  config-h.in
  configure
  doc/fdl.texi
  doc/gendocs_template
  doc/gendocs_template_min
  gnulib-tests/
  libltdl/COPYING.LIB
  libltdl/Makefile.am
  libltdl/Makefile.in
  libltdl/aclocal.m4
  libltdl/autom4te.cache/
  libltdl/config-h.in
  libltdl/configure
  m4/00gnulib.m4
  m4/gnulib-cache.m4
  m4/gnulib-common.m4
  m4/gnulib-comp.m4
  m4/gnulib-tool.m4
  m4/ltversion.m4
  m4/zzgnulib.m4
  maint.mk
);


# ---------------------------------------------------------------------------- #

mkdir -p build-aux;
mkdir -p doc;
mkdir -p m4;

ln -sr README.md README;

# Don't put in distribution
rm -f HACKING;

# Obsolete files
rm -f acinclude.m4 argz.c libltdl/config.h lt__dirent.c lt__strl.c;



# ---------------------------------------------------------------------------- #

# Remove references to `gnulib' in `configure.ac'
$SED -i '/^GL_\(EARLY\|INIT\)$/d' -e configure.ac;
$SED -i 's/ gnulib-tests\/Makefile//' configure.ac;

# Avoid `git-version-gen' in `configure.ac'
_ac_genversion_pattern='m4_esyscmd(\[build-aux\/git-version-gen ';
_ac_genversion_pattern+='\.tarball-version\])';
$SED -i "s/$_ac_genversion_pattern/\[$VERSION\]/" configure.ac;

# Drop `gnulib-tests/' from `SUBDIRS'
$SED -i 's/ gnulib-tests//' Makefile.am;


# ---------------------------------------------------------------------------- #

# Held in `GNULIB_LOCALDIR'
declare -a gnulib_diffs;
gnulib_diffs=(
  build-aux/announce-gen.diff
  build-aux/do-release-commit-and-tag.diff
  top/README-release.diff
);

# Held in `GNULIB'
declare -a gnulib_automake_diffs;
gnulib_automake_diffs=(
  build-aux/test-driver.diff
  build-aux/test-driver-1.16.3.diff
);


# ---------------------------------------------------------------------------- #

declare -a gnulib_copy;
gnulib_copy=(
  build-aux/announce-gen
  build-aux/compile
  build-aux/config.guess
  build-aux/config.sub
  build-aux/depcomp
  build-aux/do-release-commit-and-tag
  build-aux/gendocs.sh
  build-aux/git-version-gen
  build-aux/gitlog-to-changelog
  build-aux/gnu-web-doc-update
  build-aux/gnupload
  build-aux/install-sh
  build-aux/mdate-sh
  build-aux/texinfo.tex
  build-aux/update-copyright
  build-aux/useless-if-before-free
  build-aux/vc-list-files
  doc/COPYING.LESSERv2
  doc/COPYINGv2
  doc/INSTALL
  doc/fdl.texi
  doc/gendocs_template
  doc/gendocs_template_min
  m4/00gnulib.m4
  m4/gnulib-common.m4
  m4/gnulib-tool.m4
  m4/zzgnulib.m4
  top/GNUmakefile
  top/README-release
  top/maint.mk
);

for f in "${gnulib_copy[@]}"; do
  if echo "$f"|$GREP '^top/'; then
    ofile="$( $BASENAME $f; )";
  else
    ofile="$f";
  fi
  if echo "  ${gnulib_diffs[@]} "|$GREP " $f.diff "; then
    $PATCH -i $GNULIB_LOCALDIR/$f.diff -o $ofile $GNULIBDIR/$f;
  else
    cat $GNULIBDIR/$f > $ofile
  fi
  if test -x $GNULIBDIR/$f; then
    chmod a+x $ofile;
  fi
done

mv doc/COPYINGv2 COPYING;
mv doc/INSTALL INSTALL;
mv doc/COPYING.LESSERv2 libltdl/COPYING.LIB;
$SED -i "s/@PACKAGE@/$PACKAGE"/g README-release;

# Not really sure what to do with these...
declare -a gnulib_create;
gnulib_create=(
  m4/gnulib-cache.m4
  m4/gnulib-comp.m4
  gnulib-tests/Makefile.am
  lib/Makefile.am
);


# ---------------------------------------------------------------------------- #

declare -a bootstrap_copy;
bootstrap_copy=(
  build-aux/bootstrap.in
  build-aux/extract-trace
  build-aux/inline-source
  build-aux/options-parser
  build-aux/funclib.sh
);

for f in "${bootstrap_copy[@]}"; do
  cp $BOOTSTRAPDIR/$f $f;
done

# See line 195 of `bootstrap.conf' they generate a temporary `Makefile'
# and then trash it soon after.
declare -a bootstrap_deps;
bootstrap_deps=(
  libltdl/Makefile.am
  build-aux/ltmain.sh
  m4/ltversion.m4
);


# ---------------------------------------------------------------------------- #

# Generate temporary `Makefile' for `bootstrap_deps'
{
  echo 'aux_dir     = build-aux';
  echo 'ltdl_dir    = libltdl';
  echo 'macro_dir   = m4';
  echo 'AM_V_GEN    = $(am__v_GEN_$(V))';
  echo 'am__v_GEN   = $(am__v_GEN_$(AM_DEFAULT_VERBOSITY))';
  echo 'am__v_GEN_0 = @echo "  GEN      " $@; ';
  echo 'AM_V_at     = $(am__v_at_$(V))';
  echo 'am__v_at    = $(am__v_at_$(AM_DEFAULT_VERBOSITY))';
  echo 'am__v_at_0  = @';
  $SED '/^if /,/^endif$/d;/^else$/,/^endif$/d;/^include /d'  \
       Makefile.am libltdl/ltdl.mk;
} > $BOOTSTRAP_MAKEFILE;

# Build `bootstrap_deps'
$MAKE bootstrap-deps                      \
  AM_DEFAULT_VERBOSITY=0                  \
  V="$V"                                  \
  PACKAGE="$PACKAGE"                      \
  PACKAGE_BUGREPORT="$PACKAGE_BUGREPORT"  \
  PACKAGE_NAME="$PACKAGE_NAME"            \
  PACKAGE_URL="$PACKAGE_URL"              \
  VERSION="$VERSION"                      \
  SED="$SED"                              \
  srcdir=".";
status=$?;

rm -f $BOOTSTRAP_MAKEFILE;
test 0 -eq "$status" || exit $status;


# ---------------------------------------------------------------------------- #

LIBTOOLIZE=true $AUTORECONF --install;
LIBTOOLIZE=true $AUTORECONF --install libltdl;


# ---------------------------------------------------------------------------- #

##if test "$AUTOMAKE_VERSION" = "1.16.3"; then
##  gnulib_automake_diff="${gnulib_automake_diff[2]}";
##else
##  gnulib_automake_diff="${gnulib_automake_diff[1]}";
##fi
##mv build-aux/test-driver build-aux/test-driver~;
##$PATCH -i $GNULIB/$gnulib_automake_diff -o build-aux/test-driver  \
##       build-aux/test-driver~;
##rm build-aux/test-driver~;


# ---------------------------------------------------------------------------- #



# ============================================================================ #
# vim: set filetype=sh :
