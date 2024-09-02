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
cd QuantumControl.jl
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


## Making Releases

If releases need to be made for multiple packages across the organization, they must be made in the order listed in the [package table](https://github.com/JuliaQuantumControl#packages)

For each package, for a release `X.Y.Z`, e.g. `1.0.0`, do the following from the `master` branch:

- [ ] `git checkout -b release-1.0.0`
- [ ] Modify `Project.toml` to bump to the new version number, set `compat` for all dependencies in the JuliaQuantumControl org to the latest release (removing any `>=` specification)
- [ ] Make a commit with message "Release 1.0.0"
- [ ] `git push -u origin release-1.0.0`
- [ ] Create a pull request
- [ ] Apply the "no changelog" label
- [ ] Wait for continuous integration to finish
- [ ] Go to the main Github profile for the package
- [ ] Select the `release-1.0.0` branch in the top left
- [ ] Click on the commit ID of the release commit in the table title row
- [ ] Comment `@JuliaRegistrator register` on the commit
- [ ] Wait for JuliaRegistrator and Tagbot to make and tag a release, wait for all CI to finish
- [ ] In the terminal, switch to the `master` branch
- [ ] `git merge --no-ff --no-commit release-1.0.0`
- [ ] Edit `Project.toml` to append `+dev` to the version number (e.g., `1.0.0+dev`), prepend `>=` to the compat specification of all dependencies in the JuliaQuantumControl organization.
- [ ] `git commit` to make a merge commit, use "Bump version to 1.0.0+dev" as the commit message
- [ ] `git push` to push the `master`


## The QuantumControlRegistry

[Working with unregistered packages in Julia is tricky.](https://discourse.julialang.org/t/cant-figure-out-how-to-dev-install-unregistered-package/70298). Therefore, we have a [QuantumControlRegistry](https://github.com/JuliaQuantumControl/QuantumControlRegistry) to register any packages within the `JuliaQuantumControl` organization that should not be or are not ready yet for the [Julia General Registry](https://github.com/JuliaRegistries/General). Packages must be registered *either* in `QuantumControlRegistry` *or* in `General`: when a package gets added to `General`, it should be removed from `QuantumControlRegistry`.

To add the `QuantumControlRegistry` to your julia installation, run

~~~
pkg> registry add https://github.com/JuliaQuantumControl/QuantumControlRegistry.git
~~~

To add packages to `QuantumControlRegistry`, or create new releases for previously added packages, use the `LocalRegistry.register` command in the [org-level REPL](#org-level-makefile) (`make devrepl`), e.g.,

~~~
using LocalRegistry
register("./GRAPELinesearchAnalysis.jl/", registry="QuantumControlRegistry")
~~~

See
~~~
help?> register
~~~

or the [`LocalRegistry` documentation](https://github.com/GunnarFarneback/LocalRegistry.jl#readme) for details.


[JuliaQuantumControl]: https://github.com/JuliaQuantumControl
