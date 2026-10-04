# JAMA 1.2.5 is written against TNT 1.2.6, not the TNT 3 nixpkgs ships, and
# ISIS includes the headers as <tnt/...>.
{
  tnt,
  fetchurl,
}:
tnt.overrideAttrs {
  version = "1.2.6";

  src = fetchurl {
    url = "https://math.nist.gov/tnt/tnt_126.zip";
    hash = "sha256-k8fN0Ram+utnmJClLVtRMFU4jH+qrHS+6lcPjy7b1+Q=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  # The archive has no top-level directory.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/include/tnt *.h
    runHook postInstall
  '';
}
