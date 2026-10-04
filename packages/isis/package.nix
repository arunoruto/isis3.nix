{
  lib,
  stdenv,
  fetchFromGitHub,
  callPackage,
  cmake,
  makeWrapper,
  ninja,
  doxygen,
  qt6,
  qt6Packages,

  ale,
  armadillo,
  blas,
  boost188,
  bullet-double,
  cspice,
  csm,
  curl,
  eigen,
  embree3,
  gdal,
  geos,
  gsl,
  hdf5,
  highfive,
  inja,
  jama125,
  lapack,
  libGLU,
  libgeotiff,
  libpng,
  libtiff,
  libx11,
  nanoflann14,
  nlohmann_json,
  nn186,
  opencv,
  pcl,
  proj,
  protobuf,
  python3,
  rclone,
  spiceql,
  suitesparse,
  superlu,
  tnt126,
  xercesc,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "isis";
  version = "10.0.0";

  src = fetchFromGitHub {
    owner = "DOI-USGS";
    repo = "ISIS3";
    tag = "${finalAttrs.version}_LTS";
    hash = "sha256-4oNAnmQxZ4psXUYogtX2mT6LgjXS3lHYcMl+pmIZ8pY=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  cmakeDir = "../isis";

  postPatch = ''
    # get_os_version() reads /etc/os-release & co., which do not exist in
    # the build sandbox (DOI-USGS/ISIS3#5657). The string is only printed.
    substituteInPlace isis/CMakeLists.txt \
      --replace-fail 'get_os_version(osVersionString)' \
                     'set(osVersionString "${stdenv.hostPlatform.system}")'

    # FindAle asks `conda list` for the version it records in ale_version.txt.
    cat > isis/cmake/FindAle.cmake <<'EOF'
    find_path(ALE_INCLUDE_DIR NAMES Isd.h PATH_SUFFIXES ale)
    find_library(ALE_LIBRARY NAMES ale)
    get_filename_component(ALE_ROOT_INCLUDE_DIR "''${ALE_INCLUDE_DIR}" DIRECTORY)
    file(WRITE "''${CMAKE_BINARY_DIR}/ale_version.txt" "${ale.version}\n")
    EOF

    # GDAL 3.13 returns CSLConstList from GetMetadata(); ISIS wraps it in a
    # non-owning CPLStringList, which still wants a mutable char**.
    substituteInPlace isis/src/core/src/Pvl.cpp \
      --replace-fail 'CPLStringList(dataset->GetMetadata("json:ISIS3"), false)' \
                     'CPLStringList(const_cast<char **>(dataset->GetMetadata("json:ISIS3")), false)'
    substituteInPlace isis/src/base/objs/Cube/Cube.cpp \
      --replace-fail 'CPLStringList(gdalDataset()->GetMetadata("json:ISIS3"), false)' \
                     'CPLStringList(const_cast<char **>(gdalDataset()->GetMetadata("json:ISIS3")), false)'

    # conda ships the double-precision Bullet config under a separate name.
    substituteInPlace isis/cmake/FindBulletFloat64.cmake \
      --replace-fail 'CONFIGS BulletConfig-float64.cmake' 'CONFIG'
  '';

  nativeBuildInputs = [
    cmake
    ninja
    doxygen
    protobuf
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    ale
    armadillo
    blas
    boost188
    bullet-double
    cspice
    csm
    curl
    eigen
    embree3
    gdal
    geos
    gsl
    hdf5
    highfive
    inja
    jama125
    lapack
    libGLU
    libgeotiff
    libpng
    libtiff
    libx11
    nanoflann14
    nlohmann_json
    nn186
    opencv
    pcl
    proj
    protobuf
    python3
    spiceql
    suitesparse
    superlu
    tnt126
    xercesc

    qt6.qtbase
    qt6.qt5compat
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qtsvg
    qt6.qtwebchannel
    qt6Packages.qwt
  ];

  cmakeFlags = [
    (lib.cmakeBool "buildTests" false)
    (lib.cmakeBool "BUILD_CORE_TESTS" false)
    (lib.cmakeBool "buildCoverage" false)
    (lib.cmakeBool "buildDocs" false)
    (lib.cmakeBool "pybindings" false)
    (lib.cmakeBool "JP2KFLAG" false)
    (lib.cmakeFeature "UIC" "${qt6.qtbase}/libexec/uic")
    (lib.cmakeFeature "MOC" "${qt6.qtbase}/libexec/moc")
    (lib.cmakeFeature "RCC" "${qt6.qtbase}/libexec/rcc")
  ];

  # Only checked for existence at configure time; the applications read the
  # real one at runtime (see qtWrapperArgs).
  preConfigure = ''
    export ISISROOT="$PWD/isis"
  '';

  # libisis is copied into place by install(CODE ...) rather than installed
  # as a target, so CMake never rewrites its build-tree RPATH.
  preFixup = ''
    while IFS= read -r -d "" f; do
      isELF "$f" || continue
      rpath=$(patchelf --print-rpath "$f" | tr : '\n' | grep -v "^$NIX_BUILD_TOP" | paste -sd: || true)
      patchelf --set-rpath "$out/lib''${rpath:+:$rpath}" "$f"
    done < <(find "$out/lib" "$out/bin" -type f -print0)
  '';

  qtWrapperArgs = [
    "--set-default"
    "ISISROOT"
    (placeholder "out")
  ];

  # downloadIsisData is a Python script around rclone, not a Qt app.
  postFixup = ''
    wrapProgram $out/bin/downloadIsisData \
      --prefix PATH : ${lib.makeBinPath [ rclone ]}
  '';

  passthru.tests.smoke = callPackage ./test.nix { isis = finalAttrs.finalPackage; };

  meta = {
    homepage = "https://isis.astrogeology.usgs.gov";
    description = "Integrated Software for Imagers and Spectrometers: planetary image processing from USGS";
    changelog = "https://github.com/DOI-USGS/ISIS3/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.cc0;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ arunoruto ];
  };
})
