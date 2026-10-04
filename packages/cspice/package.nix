{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
}:
let
  # NAIF ships per-platform tarballs of the same toolkit; only the
  # pre-generated build scripts differ, which the CMake wrapper ignores.
  toolkit =
    {
      x86_64-linux = {
        platform = "PC_Linux_GCC_64bit";
        hash = "sha256-YKlbUaZHLxr+fkDXfr3uQ8ErtbiCNnbMx0aS3f7eBs4=";
      };
      aarch64-darwin = {
        platform = "MacM1_OSX_clang_64bit";
        hash = "sha256-DergSEQ+EcpNCTysZR2XhdTyWUYxoYPYWj1YlJ9NCqk=";
      };
    }
    .${stdenv.hostPlatform.system}
      or (throw "cspice: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "cspice";
  version = "67";

  # CMake build of CSPICE (shared lib + cspiceConfig.cmake) maintained by
  # SpiceyPy and vendored by SpiceQL; this is the commit SpiceQL pins.
  src = fetchFromGitHub {
    owner = "AndrewAnnex";
    repo = "cspice-cmake-spiceypy";
    rev = "a1e20614eb91abb23c05e1b80f5ab7815df6f677";
    hash = "sha256-npSI6P1KAWkPrwCSUACOzCbE8mk0K8EuD7UAplPnxEo=";
  };

  toolkitSrc = fetchurl {
    url = "https://naif.jpl.nasa.gov/pub/naif/misc/toolkit_N00${finalAttrs.version}/C/${toolkit.platform}/packages/cspice.tar.Z";
    inherit (toolkit) hash;
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [ cmake ];

  # The wrapper would otherwise FetchContent the tarball at configure time.
  preConfigure = ''
    mkdir -p "$NIX_BUILD_TOP/toolkit"
    tar -xf "$toolkitSrc" -C "$NIX_BUILD_TOP/toolkit"
    export CSPICE_SRC="$NIX_BUILD_TOP/toolkit/cspice"
  '';

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" false)
  ];

  meta = {
    homepage = "https://naif.jpl.nasa.gov/naif/toolkit.html";
    description = "NAIF SPICE toolkit for space mission geometry (C library)";
    license = lib.licenses.free;
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    maintainers = with lib.maintainers; [ arunoruto ];
  };
})
