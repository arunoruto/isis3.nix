# nixpkgs' jama, but on TNT 1.2.6 and installed as <jama/...> like ISIS expects.
{
  jama,
  tnt126,
}:
jama.overrideAttrs {
  __structuredAttrs = true;
  strictDeps = true;

  propagatedBuildInputs = [ tnt126 ];

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/include/jama *.h
    runHook postInstall
  '';
}
