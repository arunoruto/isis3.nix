{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "csm";
  version = "3.0.3-dec";

  src = fetchFromGitHub {
    owner = "USGS-Astrogeology";
    repo = "csm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ol+jJNTc9lHf93WbIl6jSmbUNVnW7xsy1TTQ3HsX6ac=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [ cmake ];

  meta = {
    homepage = "https://github.com/USGS-Astrogeology/csm";
    description = "Community Sensor Model API (csmapi)";
    license = lib.licenses.publicDomain;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ arunoruto ];
  };
})
