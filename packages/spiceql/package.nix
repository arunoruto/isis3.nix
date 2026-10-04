{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  cereal,
  cspice,
  curl,
  fmt,
  hdf5,
  highfive,
  nlohmann_json,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "spiceql";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "DOI-USGS";
    repo = "SpiceQL";
    tag = finalAttrs.version;
    hash = "sha256-mzFlyiNmO0RD8YNolJh2EaHLYCOYnSpqpNMUUiqePp8=";
    fetchSubmodules = true;
  };

  __structuredAttrs = true;
  strictDeps = true;

  postPatch = ''
    # The kernel database is looked up under $CONDA_PREFIX/etc/SpiceQL/db;
    # fall back to our own prefix instead of the current directory.
    substituteInPlace SpiceQL/src/utils.cpp \
      --replace-fail 'fs::absolute(condaPrefix ? condaPrefix : "")' \
                     'fs::absolute(condaPrefix ? condaPrefix : "${placeholder "out"}")'

    # _SOURCE_PREFIX is only used with SPICEQL_DEV_DB, but it would bake
    # the build directory into the library.
    substituteInPlace CMakeLists.txt \
      --replace-fail '-D_SOURCE_PREFIX="''${CMAKE_CURRENT_SOURCE_DIR}"' \
                     '-D_SOURCE_PREFIX="''${CMAKE_INSTALL_PREFIX}"'
  '';

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    cspice
    curl
    hdf5
    highfive
  ];

  # Public link interface of the SpiceQL target.
  propagatedBuildInputs = [
    cereal
    fmt
    nlohmann_json
  ];

  cmakeFlags = [
    (lib.cmakeBool "SPICEQL_BUILD_TESTS" false)
    (lib.cmakeBool "SPICEQL_BUILD_DOCS" false)
    (lib.cmakeBool "SPICEQL_BUILD_BINDINGS" false)
    (lib.cmakeBool "JSON_Install" false)
  ];

  meta = {
    homepage = "https://github.com/DOI-USGS/SpiceQL";
    description = "C++ library for querying, reading and writing NAIF SPICE kernels";
    license = lib.licenses.cc0;
    inherit (cspice.meta) platforms;
    maintainers = with lib.maintainers; [ arunoruto ];
  };
})
