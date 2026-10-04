# ISIS' EmbreeTargetShape is written against the embree 3 ray query API;
# embree 4 changed it, and conda-forge pins `embree >=3,<4`.
{
  lib,
  embree,
  fetchFromGitHub,
}:
embree.overrideAttrs (
  finalAttrs: previousAttrs: {
    version = "3.13.5";

    src = fetchFromGitHub {
      owner = "embree";
      repo = "embree";
      tag = "v${finalAttrs.version}";
      hash = "sha256-tfM4SGOFVBG0pQK9B/iN2xDaW3yjefnTtsoUad75m80=";
    };

    __structuredAttrs = true;
    strictDeps = true;

    # Same root-dir fix as nixpkgs' embree 4, minus the 4.x-only emath.h bits.
    postPatch = ''
      sed -i "s|SET(EMBREE_ROOT_DIR .*)|set(EMBREE_ROOT_DIR $out)|" \
        common/cmake/embree-config.cmake
      sed -i "s|$""{EMBREE_ROOT_DIR}/||" common/cmake/embree-config.cmake
    '';

    cmakeFlags = previousAttrs.cmakeFlags ++ [
      (lib.cmakeBool "EMBREE_ISPC_SUPPORT" false)
      (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    ];

    # GCC 15 rejects ill-formed (never instantiated) operator<< templates.
    env.NIX_CFLAGS_COMPILE = "-Wno-template-body";
  }
)
