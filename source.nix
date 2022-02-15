{ runCommandNoCC, name, src }:
runCommandNoCC name { inherit src; } ''
  mkdir -p $out
  cp -r $src/* $out/
''
