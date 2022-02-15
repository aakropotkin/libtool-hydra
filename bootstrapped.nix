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
  '';

  buildPhase = ''
    ./bootstrap --skip-git

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
