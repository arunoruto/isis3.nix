# nn-c 2.x removed delaunay_build()/delaunay_destroy() from nn.h, which
# ISIS' cnet2dem uses.
{
  nn,
  fetchFromGitHub,
}:
nn.overrideAttrs {
  version = "1.86.0";

  src = fetchFromGitHub {
    owner = "sakov";
    repo = "nn-c";
    rev = "33cbf70dec4f64836a26dcb4a885cb09b7279dd3";
    hash = "sha256-fDXAM2IDvCH1RZ2kEp/UlUin/YMRSnMBgitz1apw6Gk=";
  };

  __structuredAttrs = true;
  strictDeps = true;
}
