# JuliaQuantumControl Dev Environment

The packages within the [JuliaQuantumControl][] organization are tightly coupled. Development on any package should happen in conjunction with all other packages.

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


## Org-level Makefile

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


## The QuantumControlRegistry

[Working with unregistered packages in Julia is tricky.](https://discourse.julialang.org/t/cant-figure-out-how-to-dev-install-unregistered-package/70298). Therefore, we have a [QuantumControlRegistry](https://github.com/JuliaQuantumControl/QuantumControlRegistry) to register any packages withing the `JuliaQuantumControl` organization that should not be or are not ready yet for the [Julia General Registry](https://github.com/JuliaRegistries/General). Packages must be registered *either* in `QuantumControlRegistry` *or* in `General`: when a package gets added to `General`, it should be removed from `QuantumControlRegistry`.

To add the `QuantumControlRegistry` to your julia installation, run

~~~
pkg> registry add https://github.com/JuliaQuantumControl/QuantumControlRegistry.git
~~~

To add packages to `QuantumControlRegistry`, or create new releases for previously added packages, use the `register` command in the [org-level REPL](#org-level-makefile) (`make devrepl`), e.g.,

~~~
register("./GRAPELinesearchAnalysis.jl/", registry="QuantumControlRegistry")
~~~

See
~~~
help?> register
~~~

or the [`LocalRegistry` documentation](https://github.com/GunnarFarneback/LocalRegistry.jl#readme) for details.


[JuliaQuantumControl]: https://github.com/JuliaQuantumControl
