# ISIS links Bullet::Bullet_double and refuses a single-precision Bullet.
{
  lib,
  bullet,
}:
bullet.overrideAttrs (previousAttrs: {
  pname = "bullet-double";

  __structuredAttrs = true;
  strictDeps = true;

  cmakeFlags = previousAttrs.cmakeFlags ++ [
    (lib.cmakeBool "USE_DOUBLE_PRECISION" true)
    (lib.cmakeBool "BUILD_BULLET2_DEMOS" false)
    (lib.cmakeBool "BUILD_UNIT_TESTS" false)
    (lib.cmakeBool "BUILD_EXTRAS" false)
  ];
})
