# nanoflann 1.5 renamed the search API ISIS uses; conda-forge pins <1.5.
{
  nanoflann,
  fetchFromGitHub,
}:
nanoflann.overrideAttrs (finalAttrs: {
  version = "1.4.3";

  src = fetchFromGitHub {
    owner = "jlblancoc";
    repo = "nanoflann";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NcewcNQcI1CjMNibRF9HCoE2Ibs0/Hy4eOkJ20W3wLo=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  # Header-only. Its examples no longer build and GCC 15 wants <cstdint>.
  postPatch = ''
    sed -i '0,/#include <cmath>/s//#include <cmath>\n#include <cstdint>/' include/nanoflann.hpp
  '';

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/include include/nanoflann.hpp
    runHook postInstall
  '';
})
