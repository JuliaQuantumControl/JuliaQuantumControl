# JuliaQuantumControl Dev Environment

The packages within the [JuliaQuantumControl][] organization are tightly coupled. This repository provides a development environment that contains checkouts of all packages, together with scripts for working across the organization.

When developing on a Unix system ([WSL](https://docs.microsoft.com/en-us/windows/wsl/) is recommended on Windows), set up the development environment with

```
git clone git@github.com:JuliaQuantumControl/JuliaQuantumControl.git
cd JuliaQuantumControl
make clone
```

This clones all the active package repositories within the [JuliaQuantumControl][] organization, as well as the [`.github`](https://github.com/JuliaQuantumControl/.github) repository with the organization-wide [`CONTRIBUTING.md`](https://github.com/JuliaQuantumControl/.github/blob/master/CONTRIBUTING.md), into subfolders of `JuliaQuantumControl`. You may then navigate into any of the package folders for development, e.g.

```
cd QuantumControl.jl
make test
make devrepl
```

Run `make` within a package folder for the available targets. The development workflow for the packages is described in [`CONTRIBUTING.md`](https://github.com/JuliaQuantumControl/.github/blob/master/CONTRIBUTING.md#development-workflow).

By default, the test and documentation environments of a package use the *registered releases* of their sibling packages, or a GitHub branch specified in `[sources]`. They do not use the checkouts in the development environment. To test a package against the local checkouts of its siblings, run

```
julia ../scripts/installorg.jl
```

in the package folder, and `julia ../scripts/installorg.jl --revert` to switch back. This writes local `path` entries to the `[sources]` of `test/Project.toml` and `docs/Project.toml`, which must never be committed. See [Local checkouts of sibling packages](https://github.com/JuliaQuantumControl/.github/blob/master/CONTRIBUTING.md#local-checkouts-of-sibling-packages).


## Scripts

The `scripts` folder contains scripts that are used across the organization:

* `scripts/envcheck.jl`: Checks for the `[sources]` in the `test` and `docs` environments of a package, and helpers for running tests on Julia 1.10. Used by the package `Makefile`s and by CI, which downloads the script from the `master` branch of this repository.
* `scripts/installorg.jl`: Switch the `test` and `docs` environments of a package to the local checkouts of its sibling packages.
* `scripts/clone.jl`, `scripts/gitutils.jl`, `scripts/testall.jl`, `scripts/clean.jl`, `scripts/ctags.jl`, `scripts/check_circular_deps.jl`: Tasks across all packages, see below.


## Org-level Makefile

You may also perform some development tasks across the entire organization by using `make` within the parent `JuliaQuantumControl` folder. E.g.,

```
make pull
```

will pull the current state of all org projects from GitHub,

```
make status
```

will show the state of all checkouts, and

```
make distclean testall
```

will run `make test` for every package.

You can also run

```
make devrepl
```

for a Julia REPL with the local checkouts of all packages available. This is in addition to the development REPL for each individual package (`make devrepl` in the package folder).


[JuliaQuantumControl]: https://github.com/JuliaQuantumControl
