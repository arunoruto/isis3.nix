<a id="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Check][check-shield]][check-url]
[![Build][build-shield]][build-url]
[![ISIS][isis-shield]][isis-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <h3 align="center">isis3.nix</h3>

  <p align="center">
    USGS ISIS, the planetary image processing suite, built from source with Nix.
    <br />
    No conda, no activation scripts, no <code>--option sandbox false</code>.
    <br />
    <br />
    <a href="#usage"><strong>Get started »</strong></a>
    <br />
    <br />
    <a href="https://github.com/DOI-USGS/ISIS3">Upstream ISIS3</a>
    &middot;
    <a href="https://github.com/arunoruto/isis3.nix/issues/new?labels=bug">Report Bug</a>
    &middot;
    <a href="https://github.com/arunoruto/isis3.nix/issues/new?labels=enhancement">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#whats-in-the-box">What's in the box</a></li>
        <li><a href="#why-nix-and-not-conda">Why Nix and not conda?</a></li>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#what-had-to-be-changed-and-why">What had to be changed, and why</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About The Project

[ISIS][isis-url] (Integrated Software for Imagers and Spectrometers) is the USGS
Astrogeology toolkit for processing images from NASA and international planetary
missions. Officially it ships through conda. This repository is a Nix flake that
builds ISIS **10.0.0 LTS** and every library it needs from source. The build is
reproducible, and every patch and pinned version is explained in this repository.

It started from a need at work: conda environments kept breaking. A first attempt
in 2024 got ISIS 8.3 building, but only with the Nix build sandbox turned off,
because ISIS' CMake reads `/etc/os-release` to name the operating system. That
attempt led to [DOI-USGS/ISIS3#5657][upstream-issue]. This repository picks the
work up again for ISIS 10 and gets it building inside the sandbox.

### What's in the box

| Output | What it is |
|---|---|
| `isis` (default) | ISIS 10.0.0 LTS: 360+ command-line applications and the Qt 6 GUIs (`qview`, `qnet`, `qmos`, …) |
| `spiceql` | [SpiceQL][spiceql-url] 1.8.0, the SPICE kernel query library ISIS 9+ depends on |
| `cspice` | NAIF [CSPICE][cspice-url] N0067, built as a shared library with a CMake package config |
| `ale` | [ALE][ale-url] 1.3.0, the Abstraction Layer for Ephemerides (C++ library) |
| `csm` | [Community Sensor Model][csm-url] API 3.0.3 |
| `embree3`, `bullet-double`, `nanoflann14`, `nn186`, `tnt126`, `jama125` | Libraries nixpkgs has, but in a version or build ISIS cannot use. See [below](#what-had-to-be-changed-and-why) |
| `overlays.default` | Adds `pkgs.isis` and the `pkgs.isis3Packages` scope to your own nixpkgs |
| `devShells.default` | A shell with ISIS on `PATH` |
| `checks.isis-smoke` | Builds ISIS, then creates a cube and runs `stats` and `catlab` on it |

Every application is wrapped so `ISISROOT` already points at the installation.
You only need to provide `ISISDATA`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Why Nix and not conda?

Conda is the officially supported way to install ISIS, and it works for most
people. Nix makes different trade-offs, and for a project with this many native
dependencies those trade-offs pay off:

* **The sandbox finds hidden assumptions.** Nix builds have no network access, no
  `/etc/os-release`, and nothing installed that is not declared. That is how this
  packaging found that ISIS' build runs `cat /etc/os-release` and `conda list ale`
  at configure time. Under conda those calls just happen to work.
* **Everything is pinned, all the way down.** `flake.lock` fixes one nixpkgs
  revision, which fixes the exact compiler, glibc, Qt, GDAL, Boost and everything
  else. A conda `environment.yml` with version ranges is re-solved at install
  time and can give a different environment next month. The same flake revision
  always gives the same build.
* **Patches are visible and local.** Every deviation from upstream is a few lines
  in `packages/*/package.nix`, with a comment saying why. There is no separate
  feedstock or channel to look through.
* **Different versions without conflicts.** Here ISIS gets embree 3 and nn-c 1.86,
  while the rest of your system keeps embree 4 and nn-c 2. In conda, one
  environment can hold only one version of each.
* **No activation step.** There is no `conda activate` and no
  `isisVarInit.py`. `nix shell github:arunoruto/isis3.nix` and the tools work. Old
  versions stay on disk until you garbage-collect them, so rolling back is
  instant.

Where conda is still the better choice, honestly:

* It is the **upstream-supported** channel. Bugs found here may be packaging bugs.
* It has **prebuilt binaries for macOS** (Intel and Apple Silicon). This flake
  only targets `x86_64-linux` so far.
* There is **no binary cache yet**, so the first install compiles ISIS. That takes
  roughly 40 minutes on a 12-core machine.
* The Python side (ISIS Python bindings, the Python `ale` package) is not packaged
  yet. See the [roadmap](#roadmap).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

* [![Nix][nix-shield]][nix-url]
* [![CMake][cmake-shield]][cmake-url]
* [![Qt][qt-shield]][qt-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

* Nix with flakes enabled. The [Determinate installer][nix-installer] enables
  them by default. Otherwise, add this to `~/.config/nix/nix.conf`:
  ```
  experimental-features = nix-command flakes
  ```
* An `x86_64-linux` machine (NixOS or any other distribution).
* For most real work, an ISIS data area (`ISISDATA`) with the base data and
  mission kernels. See [Usage](#usage).

### Installation

Try it without installing anything:
```sh
nix shell github:arunoruto/isis3.nix
stats -h
```

Install it into your user profile:
```sh
nix profile add github:arunoruto/isis3.nix
```

Or add it to a NixOS / Home Manager configuration through the overlay:
```nix
{
  inputs.isis3.url = "github:arunoruto/isis3.nix";

  outputs = { nixpkgs, isis3, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ isis3.overlays.default ]; }
        ({ pkgs, ... }: { environment.systemPackages = [ pkgs.isis ]; })
      ];
    };
  };
}
```

The overlay builds against *your* nixpkgs. Only the `packages.*` outputs use the
nixpkgs revision pinned (and tested) in this repository.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE -->
## Usage

ISIS needs a data area for anything that touches camera models or SPICE.
`downloadIsisData` is included, already wrapped with `rclone`:

```sh
export ISISDATA=$HOME/isisdata
downloadIsisData base $ISISDATA            # required base data
downloadIsisData lro  $ISISDATA --no-kernels  # a mission, without its SPICE kernels
```

A quick check that needs no data at all:

```sh
makecube to=flat.cub samples=64 lines=64 bands=1 value=5
stats from=flat.cub
catlab from=flat.cub
```

For a project, use the dev shell. It prints a reminder when `ISISDATA` is unset:

```sh
nix develop github:arunoruto/isis3.nix
```

Building from a checkout:

```sh
nix build .#isis          # or .#spiceql, .#cspice, ...
nix flake check           # builds ISIS and runs the smoke test
```

For the applications themselves, see the [ISIS documentation][isis-docs].

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- WHAT CHANGED -->
## What had to be changed, and why

All changes are build-time fixes. None of them changes what ISIS computes.

**Patches to ISIS** (`packages/isis/package.nix`):

| Change | Why |
|---|---|
| `get_os_version()` call replaced with the Nix system string | It reads `/etc/os-release`, `/etc/lsb-release`, … and fails hard when none exist, which is always the case in the build sandbox. The result is only printed. ([#5657][upstream-issue]) |
| `FindAle.cmake` rewritten without `conda list ale --json` | It asks conda for ALE's version at configure time, and the build breaks when conda is missing. |
| `FindBulletFloat64.cmake` looks for the normal `BulletConfig.cmake` | conda-forge ships the double-precision config under a separate file name. nixpkgs ships one Bullet, built in double precision here. |
| `const_cast` around `GDALDataset::GetMetadata()` (`Pvl.cpp`, `Cube.cpp`) | GDAL 3.13 made it return `CSLConstList`. ISIS wraps the result in a non-owning `CPLStringList`, which still wants `char**`. |
| RPATH cleanup in `preFixup` | `libisis` is copied into place with `install(CODE …)` instead of being installed as a target, so CMake never removes its build-tree RPATH. |
| Tests, docs, coverage and Python bindings disabled | They need ISIS test data and a working Python binding setup. A smoke test runs instead. |

**SpiceQL** needed two small patches. It looked for its kernel database only under
`$CONDA_PREFIX`, and it compiled the build directory path into the library.
**cspice** uses the [CMake wrapper from SpiceyPy][cspice-cmake] that SpiceQL
vendors. The NAIF tarball is fetched by Nix instead of downloaded during the build.

**Library versions ISIS needs that differ from nixpkgs:**

| Package | nixpkgs has | ISIS needs | Reason |
|---|---|---|---|
| `embree3` | 4.4 | 3.13.5 | `EmbreeTargetShape` uses the embree 3 ray query API. Also needs `-Wno-template-body` for GCC 15. |
| `bullet-double` | 3.25 (single) | 3.25 (double) | ISIS refuses a single-precision Bullet. |
| `nanoflann14` | 1.7 | 1.4.3 | 1.5 renamed the search API. The header also needed `<cstdint>` for GCC 15. |
| `nn186` | 2.0.8 | 1.86 | 2.x dropped `delaunay_build()`, which `cnet2dem` uses. |
| `tnt126`, `jama125` | TNT 3.0.12 | TNT 1.2.6 | JAMA 1.2.5 is written against TNT 1.x, and ISIS includes both as `<tnt/…>`, `<jama/…>`. |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [x] ISIS 10.0.0 LTS building inside the Nix sandbox on `x86_64-linux`
- [x] SpiceQL, cspice, ALE and CSM as standalone packages
- [x] Smoke test as a flake check
- [ ] Python `ale` package, so `ale::load()` (used by `spiceinit` without `web=true`) works
- [ ] USGSCSM plugin
- [ ] Binary cache, so users do not compile ISIS themselves
- [ ] Upstream the sandbox fixes (`ISIS_OS_VERSION` override, optional conda in `FindAle`)
- [ ] `aarch64-linux` and `aarch64-darwin`
- [ ] Kakadu / JPEG 2000 support (Kakadu is proprietary)
- [ ] Upstream to nixpkgs

See the [open issues][issues-url] for the full list.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are welcome, especially from people who use ISIS daily and can tell
whether an application behaves as it should.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Format with `nix fmt` and make sure `nix flake check` passes
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a pull request

When you add a patch or pin a version, add a comment next to it explaining why,
and add a row to the tables above.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

The Nix expressions in this repository are distributed under the MIT License. See
`LICENSE` for details. ISIS itself is public domain (CC0) software of the U.S.
Geological Survey. Each packaged library keeps its own license, as listed in its
`meta.license`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Mirza Arnaut, [@arunoruto](https://github.com/arunoruto)

Project link: [https://github.com/arunoruto/isis3.nix](https://github.com/arunoruto/isis3.nix)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [USGS Astrogeology Science Center][isis-url] for ISIS, SpiceQL, ALE and CSM
* [NAIF / JPL][cspice-url] for the SPICE toolkit
* [Andrew Annex][cspice-cmake] for the CMake build of CSPICE
* [nixpkgs][nixpkgs-url] and its maintainers, for everything else in the closure
* [Best-README-Template][readme-template]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[check-shield]: https://img.shields.io/github/actions/workflow/status/arunoruto/isis3.nix/check.yaml?branch=main&label=check&style=for-the-badge
[check-url]: https://github.com/arunoruto/isis3.nix/actions/workflows/check.yaml
[build-shield]: https://img.shields.io/github/actions/workflow/status/arunoruto/isis3.nix/build.yaml?branch=main&label=build&style=for-the-badge
[build-url]: https://github.com/arunoruto/isis3.nix/actions/workflows/build.yaml
[isis-shield]: https://img.shields.io/badge/ISIS-10.0.0_LTS-blue?style=for-the-badge
[isis-url]: https://isis.astrogeology.usgs.gov
[issues-shield]: https://img.shields.io/github/issues/arunoruto/isis3.nix.svg?style=for-the-badge
[issues-url]: https://github.com/arunoruto/isis3.nix/issues
[license-shield]: https://img.shields.io/github/license/arunoruto/isis3.nix.svg?style=for-the-badge
[license-url]: https://github.com/arunoruto/isis3.nix/blob/main/LICENSE
[nix-shield]: https://img.shields.io/badge/Nix-5277C3?style=for-the-badge&logo=nixos&logoColor=white
[nix-url]: https://nixos.org
[cmake-shield]: https://img.shields.io/badge/CMake-064F8C?style=for-the-badge&logo=cmake&logoColor=white
[cmake-url]: https://cmake.org
[qt-shield]: https://img.shields.io/badge/Qt_6-41CD52?style=for-the-badge&logo=qt&logoColor=white
[qt-url]: https://www.qt.io
[nix-installer]: https://github.com/DeterminateSystems/nix-installer
[nixpkgs-url]: https://github.com/NixOS/nixpkgs
[isis-docs]: https://astrogeology.usgs.gov/docs/
[upstream-issue]: https://github.com/DOI-USGS/ISIS3/issues/5657
[spiceql-url]: https://github.com/DOI-USGS/SpiceQL
[cspice-url]: https://naif.jpl.nasa.gov/naif/toolkit.html
[cspice-cmake]: https://github.com/AndrewAnnex/cspice-cmake-spiceypy
[ale-url]: https://github.com/DOI-USGS/ale
[csm-url]: https://github.com/USGS-Astrogeology/csm
[readme-template]: https://github.com/othneildrew/Best-README-Template
