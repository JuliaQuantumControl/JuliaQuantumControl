# JuliaQuantumControl Dev Environment

The packages within the [JuliaQuantumControl][] organization are tightly coupled:

| Package | CI Status |
| --- | --- |
|[QuantumPropagators.jl](https://github.com/JuliaQuantumControl/QuantumPropagators.jl) | [![Build Status](https://github.com/JuliaQuantumControl/QuantumPropagators.jl/workflows/CI/badge.svg)](https://github.com/JuliaQuantumControl/QuantumPropagators.jl/actions) |
|[QuantumControlBase.jl](https://github.com/JuliaQuantumControl/QuantumControlBase.jl) | [![Build Status](https://github.com/JuliaQuantumControl/QuantumControlBase.jl/workflows/CI/badge.svg)](https://github.com/JuliaQuantumControl/QuantumControlBase.jl/actions) |
|[Krotov.jl](https://github.com/JuliaQuantumControl/Krotov.jl) | [![Build Status](https://github.com/JuliaQuantumControl/Krotov.jl/workflows/CI/badge.svg)](https://github.com/JuliaQuantumControl/Krotov.jl/actions) |
|[GRAPE.jl](https://github.com/JuliaQuantumControl/GRAPE.jl) | [![Build Status](https://github.com/JuliaQuantumControl/GRAPE.jl/workflows/CI/badge.svg)](https://github.com/JuliaQuantumControl/GRAPE.jl/actions) |
|[QuantumControl.jl](https://github.com/JuliaQuantumControl/QuantumControl.jl) | [![Build Status](https://github.com/JuliaQuantumControl/QuantumControl.jl/workflows/CI/badge.svg)](https://github.com/JuliaQuantumControl/QuantumControl.jl/actions) |

Development on any package should happen in conjunction with all other packages.

When developing on a Unix system ([WSL](https://docs.microsoft.com/en-us/windows/wsl/) is recommended on Windows), you should use this repository to set up a development environment:

```
git clone git@github.com:JuliaQuantumControl/JuliaQuantumControl.git
cd JuliaQuantumControl
make clone
```

This will clone all the active project repos within the [JuliaQuantumControl][] organization into a subfolder of `JuliaQuantumControl`. You may then navigate into any of the project folders for development, e.g.

```
cd QuantumControlBase.jl
make test
make devrepl
```

The `Makefile` for each project is set up such that testing happens automatically against the current state of all sibling folders (the entire organization). Run just `make` within each project for available make-targets.

You may also perform some development tasks across the entire organization by using `make` within the parent `JuliaQuantumControl` folder. E.g.,

```
make pull
```

will pull the current state of all org projects from Github,

```
make status
```

will show the state of all checkouts, and

```
make distclean testall
```

will run a complete set of tests for the entire organization.

You can also run

```
make devrepl
```

for a Julia REPL with the dev-version of all projects available. Note that this is in addition to the development REPL available for each individual project (`make devrepl` in the project folder), which also has access to the sibling projects.

[JuliaQuantumControl]: https://github.com/JuliaQuantumControl
