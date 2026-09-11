import Pkg

# ORG_PACKAGES must be ordered by their internal dependencies: Later packages
# can depend on earlier ones, but not vice versa.
ORG_PACKAGES = [
    "QuantumPropagators",
    "QuantumGradientGenerators",
    "Krotov",
    "GRAPE",
    "ParameterizedQuantumControl",
    "QuantumControl",
    "QuantumControlTestUtils",
    "GRAPELinesearchAnalysis",
    "TwoQubitWeylChamber",
]


"""Return which one of ORG_PACKAGES we're currently in.

This is determined by the `GITHUB_REPOSITORY` environment variable or the
folder name of the current git checkout.

If the current package cannot be determined, return an empty string.
"""
function get_current_package()
    if "GITHUB_REPOSITORY" ∈ keys(ENV)
        reponame = split(ENV["GITHUB_REPOSITORY"], "/")[end]
    else
        git_root = find_git_root()
        reponame = basename(git_root)
    end
    for package in ORG_PACKAGES
        if !isnothing(match(Regex("^$package(\\.jl)?\$"), reponame))
            return package
        end
    end
    return ""
end


"""Return the absolute path of the folder containing `.git`.

If not `.git` folder can be found, return the current working directory.
"""
function find_git_root()
    root = pwd()
    while !isdir(joinpath(root, ".git"))
        parent = dirname(root)
        if root == parent
            return pwd()
        end
        root = parent
    end
    return root
end


# Julia 1.13 requires the `RegistryInstance` that an entry belongs to as the
# first argument of `registry_info`. Earlier versions take the entry alone.
if hasmethod(Pkg.Registry.registry_info, Tuple{Pkg.Registry.PkgEntry})
    registry_info(_registry, entry) = Pkg.Registry.registry_info(entry)
else
    registry_info(registry, entry) = Pkg.Registry.registry_info(registry, entry)
end


# Julia 1.13 records the dependencies of a registered version as a `Set{UUID}`.
# Earlier versions use a `Dict{String,UUID}` mapping names to UUIDs.
dep_uuids(version_deps::AbstractDict) = values(version_deps)
dep_uuids(version_deps) = version_deps


"""Return the UUIDs of the registered `ORG_PACKAGES`, mapped to their names.

Org packages that are not in any reachable registry are omitted. The registries
must have been added/updated before calling this.
"""
function org_package_names()
    names = Dict{Base.UUID,String}()
    for reg in Pkg.Registry.reachable_registries()
        for (uuid, entry) in reg
            if entry.name in ORG_PACKAGES
                names[uuid] = entry.name
            end
        end
    end
    return names
end


"""Return the `ORG_PACKAGES` that `package` directly depends on.

The `names` are the UUID-to-name map from `org_package_names`. The dependencies
are read from the latest registered version of `package` in any reachable
registry, which approximates the dependencies of the `master` version that we
actually install. A `package` that is unregistered, or that does not depend on
any other `ORG_PACKAGES`, contributes no edges. The registries must have been
added/updated before calling this.
"""
function org_dependencies(package, names)
    deps = Set{String}()
    for reg in Pkg.Registry.reachable_registries()
        for (_uuid, entry) in reg
            entry.name == package || continue
            info = registry_info(reg, entry)
            isempty(info.version_info) && continue
            vmax = maximum(keys(info.version_info))
            for (vrange, version_deps) in info.deps
                vmax in vrange || continue
                for uuid in dep_uuids(version_deps)
                    depname = get(names, uuid, nothing)
                    if !isnothing(depname)
                        push!(deps, depname)
                    end
                end
            end
        end
    end
    return deps
end


"""Return the transitive `ORG_PACKAGES` dependency closure of `direct`.

Starting from the `direct` package names, follow `org_dependencies` edges until
no new `ORG_PACKAGES` are discovered. The result includes the `direct` packages
themselves. This is the set of org packages that must be dev-installed: a *bare*
list of direct dependencies would let Pkg pull a transitive org dependency from
the registry, which fails when the current package is a new breaking version
that no released sibling is compatible with yet.
"""
function org_dependency_closure(direct)
    names = org_package_names()
    closure = Set{String}()
    todo = collect(direct)
    while !isempty(todo)
        package = pop!(todo)
        package in closure && continue
        push!(closure, package)
        for dep in org_dependencies(package, names)
            dep in closure || push!(todo, dep)
        end
    end
    return closure
end


"""Install dev-versions of all the projects in the JuliaQuantumControl org.

```julia
installorg(;github="add", localfolders=true, dependencies_only=true, precompile=true)
```

dev-installs packages from `ORG_PACKAGES` into the current environment. By
default, the transitive closure of the `ORG_PACKAGES` that the current
`Project.toml` depends on (directly or via another org package) will be
installed. By setting `dependencies_only=false`, *all* packages in
`ORG_PACKAGES` will be installed (which may modify `Project.toml`).

With `precompile=false`, the final `Pkg.precompile()` is skipped. This is useful
in CI steps whose subsequent Julia process runs under non-default compile flags
(e.g. `--check-bounds=yes` or `--code-coverage`): such a process keys its
precompile cache on those flags and cannot reuse caches built here under the
default flags, so precompiling now would be wasted work. In that case, rely on
load-time precompilation in the consuming process (with cross-run caching of the
depot) instead. As a script, pass `--no-precompile` for the same effect.

It is assumed that the organization has been set up with the clone.jl script.
That is, from the JuliaQuantumControl folder, the subprojects are in direct
subfolders, e.g. "QuantumControl.jl", and from the perspective of each
package, the sibling packages are in sibling folders.

Thus, the install scripts will check for the checkouts to dev-install as
subfolders of the JuliaQuantumControl repo containing this function (devrepl in
JuliaQuantumControl) or in a sibling folder (devrepl of a package). If neither
is available (e.g, when running on Github CI), or when `localfolders=false`, it
will install the master branch of any sibling package from Github. For
`github="add"`, this is done via `Pkg.add`, and for `github="develop"` via
`Pkg.develop`. Any other value (e.g.  `github=false`) prevents installation
from Github.
"""
function installorg(;
    github = "add",
    localfolders = true,
    dependencies_only = true,
    precompile = true
)
    Pkg.Registry.add(Pkg.RegistrySpec("General"))
    Pkg.Registry.add(
        Pkg.RegistrySpec(
            url = "https://github.com/JuliaQuantumControl/QuantumControlRegistry.git"
        )
    )
    Pkg.Registry.update()
    project_toml = Pkg.project()
    current_package = get_current_package()
    git_root = find_git_root()
    if current_package == ""
        @info "No current package; CWD is $git_root"
    else
        @info "Current package is $current_package at $git_root"
    end
    # By default we install the *transitive* closure of the org packages that
    # the current project depends on. Restricting to the directly-listed
    # dependencies would let Pkg pull a transitive org dependency (e.g.
    # QuantumControl, pulled in by QuantumControlTestUtils) from the registry,
    # which fails for a breaking release as described below. With
    # `dependencies_only=false`, *all* org packages are installed instead.
    if dependencies_only
        direct = [p for p in ORG_PACKAGES if p in keys(project_toml.dependencies)]
        needed = org_dependency_closure(direct)
    else
        needed = Set(ORG_PACKAGES)
    end
    # We collect *all* sibling packages and install them together, so that the
    # environment is only ever resolved as a consistent set of development
    # versions. Installing the packages one at a time would force Pkg to fall
    # back to the *released* (registered) version of any not-yet-installed
    # sibling. That fails whenever the current package is a new breaking version
    # that no released sibling is compatible with yet (e.g. when releasing a
    # breaking QuantumPropagators version: the released downstream packages
    # still require the previous version, so no consistent environment exists
    # until every sibling is taken from a development version simultaneously).
    #
    # `develop_specs` are installed from a local checkout (`path`); `add_specs`
    # are installed from the master branch on Github. The current package itself
    # is always developed from its local path, and -- crucially -- *last*, so
    # that its (single) resolve already sees every sibling as a development
    # version rather than pulling siblings from the registry.
    add_specs = Pkg.PackageSpec[]
    develop_specs = Pkg.PackageSpec[]
    current_relpath = nothing
    for package in reverse(ORG_PACKAGES)
        if package == current_package
            # We use a relative path to avoid problems with `[sources]`.
            # See https://github.com/JuliaLang/Pkg.jl/issues/4426
            current_relpath = relpath(git_root, pwd())
            continue
        end
        if !(package in needed)
            @info "Skipping $package (not in dependency closure)"
            continue
        end
        path_candidates = [
            joinpath(@__DIR__, "..", "$package.jl"),
            joinpath(git_root, "$package.jl"),
            joinpath(dirname(git_root), "$package.jl"),
        ]
        local_path = nothing
        if localfolders
            for pkg_path ∈ path_candidates
                if isdir(pkg_path)
                    local_path = pkg_path
                    break
                end
            end
        end
        if !isnothing(local_path)
            @info "Will dev-install $package from $local_path"
            push!(develop_specs, Pkg.PackageSpec(path = local_path))
        elseif github == "add"
            @info "Will add $package#master from Github"
            push!(
                add_specs,
                Pkg.PackageSpec(
                    url = "https://github.com/JuliaQuantumControl/$package.jl",
                    rev = "master"
                )
            )
        elseif github == "develop"
            @info "Will dev-install $package#master from Github"
            # `develop` does not accept a `rev`; it tracks the default branch.
            push!(
                develop_specs,
                Pkg.PackageSpec(
                    url = "https://github.com/JuliaQuantumControl/$package.jl"
                )
            )
        else
            @error "$package could not be installed (github=false)"
        end
    end
    # Install siblings first (Github-master `add_specs`, then local/Github
    # `develop_specs`), and the current package last.
    if !isempty(add_specs)
        @info "Add $(length(add_specs)) package(s) from Github master"
        Pkg.add(add_specs)
    end
    if !isnothing(current_relpath)
        @info "Dev-install $current_package as current project from $git_root (relative path `$current_relpath`)"
        push!(develop_specs, Pkg.PackageSpec(path = current_relpath))
    end
    if !isempty(develop_specs)
        @info "Dev-install $(length(develop_specs)) package(s)"
        Pkg.develop(develop_specs)
    end
    @info "Instantiate"
    Pkg.instantiate()
    if precompile
        @info "Precompile"
        Pkg.precompile()
    else
        @info "Skipping precompile (precompile=false)"
    end
    @info "Status"
    Pkg.status()
end

if abspath(PROGRAM_FILE) == @__FILE__
    installorg(precompile = !("--no-precompile" in ARGS))
end
