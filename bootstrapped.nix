{ stdenv
, name
, src
, gitMinimal
, autoconf
, automake
, m4
, perl
, help2man
, hostname
, texinfoInteractive
}:
stdenv.mkDerivation {
  name = name + "-bootstrapped";
  inherit src;

  dontConfigure     = true;
  dontPatchShebangs = true;

  nativeBuildInputs = [
    gitMinimal
    autoconf
    automake
    m4
    perl
    help2man
    hostname
    texinfoInteractive
  ];
  
  propagatedBuildInputs = [
    autoconf
    automake
    m4
    perl
    help2man
    hostname
    texinfoInteractive
  ];

  patchPhase = ''
    echo ${toString src.revCount} > .serial
    echo 2.4.6 > .prev-version
    echo 2.4.6.63-${src.shortRev}-dirty > .version
    ls
  '';

  buildPhase = ''
    ./bootstrap --skip-git -c

    _old_prefix=$prefix
    prefix=$PWD
    _makeSymlinksRelative
    _old_prefix=$_old_prefix
  '';

  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';

  postFixup = ''
    mv $out/share/* $out/
    rmdir $out/share
  '';
}
