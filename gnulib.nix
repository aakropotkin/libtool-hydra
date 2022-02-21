{ lib
, stdenv
, src
, python3
, pname   ? "gnulib"
, version ? "0"
}:
stdenv.mkDerivation {
  inherit pname version src;

  postPatch = ''
    patchShebangs gnulib-tool.py
  '';

  buildInputs = [python3];

  installPhase = ''
    mkdir -p $out/bin
    cp -r * $out/
    ln -s $out/lib $out/include
    ln -s $out/gnulib-tool $out/bin/
  '';

  # Do not change headers to avoid updating all vendored build files
  dontFixup = true;
  
  meta = with lib; {
    homepage = "https://www.gnu.org/software/gnulib";
    description = "Central location for code to be shared among GNU packages";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
  };
}
