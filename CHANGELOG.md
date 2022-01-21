# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

Type of changes
---------------

Added for new features.
Changed for changes in existing functionality.
Deprecated for soon-to-be removed features.
Removed for now removed features.
Fixed for any bug fixes.
Security in case of vulnerabilities.

-->

## [0.6.0b0] - 2021-01-21

### Added

- Add more SGS models options: dynamic, shear_imp, vreman in addition to the
  default one constant. Dynamic remains to be tested.
- Add more boundary conditions, including no-slip.
- Utilities module.
- Output u_star and other global statistics in to spatial_means.txt
- Added cases Python sub package to save different configurations
- Added penalty modules
- Stratification
- Stability functions, i.e. stratification correction terms implemented in
  `strat_correct.f` and `newton.f` for the `moeng.f` boundary condition
- Sponge region

### Changed

- Disabled Coriolis forcing for the time being
- Debug flags during compilations
- Use Snakemake modules
- Upgrade Snek5000 API to 0.8.0

### Fixed

- Use of variable properties (SGS model) with temperature

## [0.5.0b0] - 2020-09-02

### Added

- Parameter section WMLES to toggle experimental code modifications to boundary conditions and SGS model: (bc-3rd, npow, sgs-delta, temporal filtering)
- New subcommand `launch release` to generate a Fortran-only tarball
- Non uniform meshes 11 and 12 and ability to specify hard coded mesh coordinates

### Changed

- Migrate to Nek5000 v19

### Removed

- Output of velocity gradient files which relies on `torque_calc` subroutine.

### Fixed

- Requirements: pymech and zstandard
- Working `SNEK_DEBUG` options and appopriate debug flags in Snakefile

## [0.4.0b0] - 2020-07-15

### Added

- Total shear stresses are saved in statistics files
- Helper bash functions pwd-nek
- Parameter to set wall location != 0
- WIP: simulation loader

### Changed

- All #define macros were translated to fortran parameters
- Use gcc-8 in local machine archmage
- Coordinates for stats module: z is vertical direction
- Snakemake, simul.py (renamed from simple.py), organize.py improvements

### Fixed

- Critical bug in SGS: unintialized parameter C0
- Statistics sampling rate
- Documentation build

### Removed

- Bulk velocity forcing


## [0.3.0a0] - 2020-06-02

### Added

- Writes initial condition

### Changed

- Implicit none in user subroutines (#6)
- Initial condition only adds perturbation near wall (637727aa)
- Uses snek5000

### Removed

- set_forcing

### Fixed

- Coriolis term sign
- Userf only has a coriolis term and equivalent of geostrophic pressure
  gradient term

## [0.2.2] - 2020-05-08

### Added

- Pre-commit: black, flake8, isort fixing and linting support
- Jupyterlab and ipykernel configuration snakemake rules
- Job management script - organize.py
- New module: const

### Changed

- Parameters for Maronga case
- Compilation is now parallel
- Two-step archival, tar and compress

### Fixed

- Snakemake: gslib dependency before compiling
- Snakemake: Tee output to log file

### Removed

- Requirements files produced using pip-tools

## [0.2.1] - 2020-04-14

### Added
- Tar shell functions in activate script
- Module `eturb.clusters` for job submission

### Changed
- Conda environment packages
- Reduced pressure residual tolerance for divergence check

### Fixed
- Bugfixes for simulation parameter loading, restart
- Snakefile dependencies for running a simulation

## [0.2.0] - 2020-03-22

### Added
- KTH toolbox
- Coriolis force
- Job submission in cluster
- More user_params

### Changed
- Archives use zstd compression
- user_params is a dictionary

### Fixed
- Initial condition bug in setting velocities in `useric`
- Cs - Cs**2 in `eddy_visc`
- Assert exit code of snakemake results in tests
- Subroutine `set_forcing` uses ux..  instead of vx

## [0.1.1] - 2020-01-27

### Added
- Templates in `abl.templates` subpackage
- Expand parameters and write methods in class `Operators`
- Improved tests and documentation
- Solver `abl` respects parameters and writes box and SIZE files.

### Changed
- Snakecase for `nek` parameters

## [0.1.0] - 2020-01-23

### Added
- Uses `fluidsim` framework for creating a scripting layer
- Package `abl` with a single module and an `abl.Output` class
- New sub-packages and modules under `eturb`: `solvers, output, info, log,
  make, magic, operators`
- Testing with `pytest`, and CI on GitHub actions
- Detailed documentation
- Versioning with `setuptools_scm`

### Changed
- Extra requirements `[test]` renamed to `[tests]`
- Rename case files `3D_ABL` -> `abl` and directory `abl_nek5000` -> `abl`
- Overall reorganization of modules and Snakemake + configuration files.

## [0.0.1] - 2020-01-17

### Added
- Scripting for managing run parameters `eturb.params`
- Python packaging
- Sphinx + Doxygen + Breathe documentation


[Unreleased]: https://github.com/exabl/snek5000-abl/compare/0.6.0b0...HEAD
[0.6.0b0]: https://github.com/exabl/snek5000-abl/compare/0.5.0a0...0.6.0b0
[0.5.0b0]: https://github.com/exabl/snek5000-abl/compare/0.4.0a0...0.5.0b0
[0.4.0b0]: https://github.com/exabl/snek5000-abl/compare/0.3.0a0...0.4.0b0
[0.3.0a0]: https://github.com/exabl/snek5000-abl/compare/0.2.2...0.3.0a0
[0.2.2]: https://github.com/exabl/snek5000-abl/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/exabl/snek5000-abl/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/exabl/snek5000-abl/compare/0.1.1...0.2.0
[0.1.1]: https://github.com/exabl/snek5000-abl/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/exabl/snek5000-abl/compare/0.0.1...0.1.0
[0.0.1]: https://github.com/exabl/snek5000-abl/releases/tag/0.0.1
