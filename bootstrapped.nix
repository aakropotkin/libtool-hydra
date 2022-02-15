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

  dontPatch         = true;
  dontConfigure     = true;
  dontPatchShebangs = true;

  nativeBuildInputs = [
    gitMinimal
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

  buildPhase = ''
    ./bootstrap
    _old_prefix=$prefix
    prefix=$PWD
    _makeSymlinksRelative
    _old_prefix=$_old_prefix
  ''; 

  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
