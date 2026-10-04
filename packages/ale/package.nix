{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  eigen,
  nlohmann_json,
  python3,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ale";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "DOI-USGS";
    repo = "ale";
    tag = finalAttrs.version;
    hash = "sha256-XoBTwTwRex8UuKfe/09FlG1zEO8dzM6yN4TJd0PPr80=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [ cmake ];

  # ale::load() embeds Python and imports the `ale` Python module at runtime.
  buildInputs = [
    eigen
    python3
  ];

  propagatedBuildInputs = [ nlohmann_json ];

  cmakeFlags = [
    (lib.cmakeBool "ALE_BUILD_LOAD" true)
    (lib.cmakeBool "ALE_BUILD_TESTS" false)
    (lib.cmakeBool "ALE_BUILD_DOCS" false)
  ];

  meta = {
    homepage = "https://github.com/DOI-USGS/ale";
    description = "Abstraction Layer for Ephemerides (C++ library)";
    license = lib.licenses.cc0;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ arunoruto ];
  };
})
