# Switch the `test` and `docs` environments of a package to the local checkouts
# of its sibling packages in the JuliaQuantumControl development environment.
#
# From the root of a package checkout (e.g. `QuantumControl.jl`), run
#
#     julia ../scripts/installorg.jl [ENV...] [--revert] [--no-precompile]
#
# where `ENV` are the environment folders to modify (default: `test` and
# `docs`, if they exist). With `--revert`, the environments are restored to
# their state before `installorg` (registered releases or URL `[sources]` of
# siblings).
#
# This is *not* part of the default workflow: `make test` and CI use the
# registered versions of sibling packages, or the URL `[sources]` committed in
# `test/Project.toml` and `docs/Project.toml`. See CONTRIBUTING.md.
#
# On Julia >= 1.11, sibling packages are switched to local checkouts by writing
# relative `path` entries to the `[sources]` of the environment's
# `Project.toml`. These entries must never be committed (the `envcheck.jl lint`
# CI check rejects them). On Julia 1.10, which ignores `[sources]`, the
# siblings are dev-installed with `Pkg.develop` instead. In both cases,
# `installorg` keeps a backup of the original `Project.toml` for `--revert`.

import Pkg
import TOML

# All packages in the JuliaQuantumControl org that are part of the development
# environment (cloned by `make clone`). The order is not significant.
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

const ORG_ROOT = dirname(@__DIR__)


"""Return the path of the local checkout of an org `package`, or `nothing`."""
function local_checkout(package)
    path = joinpath(ORG_ROOT, "$package.jl")
    return isfile(joinpath(path, "Project.toml")) ? path : nothing
end


"""Return the `ORG_PACKAGES` that the local checkout of `package` depends on.

Both `[deps]` and `[weakdeps]` count. A `package` without a local checkout
contributes no dependencies.
"""
function org_dependencies(package)
    path = local_checkout(package)
    isnothing(path) && return Set{String}()
    project = TOML.parsefile(joinpath(path, "Project.toml"))
    names = union(keys(get(project, "deps", Dict())), keys(get(project, "weakdeps", Dict())))
    return Set(filter(in(ORG_PACKAGES), names))
end


"""Return the transitive `ORG_PACKAGES` dependency closure of `direct`.

The result includes the `direct` packages themselves. All of them must be
switched to local checkouts together: if only the direct dependencies were
switched, Pkg would take a transitive org dependency from the registry, which
fails when a local checkout is a new breaking version that no released sibling
is compatible with yet.
"""
function org_dependency_closure(direct)
    closure = Set{String}()
    todo = collect(direct)
    while !isempty(todo)
        package = pop!(todo)
        package in closure && continue
        push!(closure, package)
        for dep in org_dependencies(package)
            dep in closure || push!(todo, dep)
        end
    end
    return closure
end


"""Return the name of the package that contains the environment folder `env`.

For `test` or `docs` inside a package checkout, this is the name of the
package. For an environment that is not a sub-folder of a package (e.g., the
root of the development environment), return `nothing`.
"""
function parent_package(env)
    parent_toml = joinpath(dirname(abspath(env)), "Project.toml")
    if abspath(env) != ORG_ROOT && isfile(parent_toml)
        return get(TOML.parsefile(parent_toml), "name", nothing)
    end
    return nothing
end


"""Return the file in which `installorg` saves the original `Project.toml` of `env`.

The backups are in the `.installorg` folder of the development environment
(ignored by git), so that `--revert` can restore uncommitted changes.
"""
function backup_file(env)
    package = something(parent_package(env), "JuliaQuantumControl")
    envname = basename(rstrip(abspath(env), '/'))
    return joinpath(ORG_ROOT, ".installorg", package, envname, "Project.toml")
end


"""Switch the environment in the folder `env` to local sibling checkouts."""
function installorg(env; precompile = true)
    project_file = joinpath(env, "Project.toml")
    own = parent_package(env)
    deps = collect(keys(get(TOML.parsefile(project_file), "deps", Dict())))
    if !isnothing(own)
        # The org dependencies of the package itself (which is in the
        # environment via `{path = ".."}`) must also be local checkouts
        own_project = TOML.parsefile(joinpath(dirname(abspath(env)), "Project.toml"))
        append!(deps, keys(get(own_project, "deps", Dict())))
        append!(deps, keys(get(own_project, "weakdeps", Dict())))
    end
    direct = [p for p in ORG_PACKAGES if (p in deps) && (p != own)]
    needed = setdiff(org_dependency_closure(direct), [own])
    siblings = Dict{String,String}()  # name => path relative to `env`
    for package in sort(collect(needed))
        path = local_checkout(package)
        if isnothing(path)
            @warn "No local checkout of $package: using registered version or URL source"
        else
            siblings[package] = relpath(realpath(path), realpath(env))
        end
    end
    @info "Switching $project_file to local checkouts" siblings
    backup = backup_file(env)
    if !isfile(backup)  # keep the original backup if `installorg` runs repeatedly
        mkpath(dirname(backup))
        cp(project_file, backup)
    end
    if VERSION >= v"1.11"
        project = Pkg.Types.read_project(project_file)
        for (package, path) in siblings
            uuid = TOML.parsefile(joinpath(ORG_ROOT, "$package.jl", "Project.toml"))["uuid"]
            project.deps[package] = Base.UUID(uuid)
            project.sources[package] = Dict{String,Any}("path" => path)
        end
        Pkg.Types.write_project(project, project_file)
        Pkg.activate(env)
        Pkg.resolve()
    else
        Pkg.activate(env)
        specs = [Pkg.PackageSpec(path = joinpath(env, path)) for path in values(siblings)]
        if !isnothing(own)
            # The package itself goes last, so that its resolve already sees all
            # siblings as development versions.
            push!(specs, Pkg.PackageSpec(path = dirname(abspath(env))))
        end
        isempty(specs) || Pkg.develop(specs)
    end
    Pkg.instantiate()
    precompile && Pkg.precompile()
    Pkg.status()
end


"""Restore the environment in the folder `env` to its state before `installorg`.

This restores `Project.toml` from the backup made by `installorg` (or, if there
is no backup, from git) and re-instantiates the environment from scratch. Just
removing `[sources]` entries and re-resolving does not reliably switch back from
local checkouts (it does not work on Julia 1.10 and 1.11).
"""
function revertorg(env; precompile = true)
    project_file = joinpath(env, "Project.toml")
    manifest_file = joinpath(env, "Manifest.toml")
    backup = backup_file(env)
    if isfile(backup)
        cp(backup, project_file; force = true)
        rm(backup)
    else
        @warn "No backup of $project_file from installorg: restoring the committed version"
        run(`git checkout -- $project_file`)
    end
    rm(manifest_file; force = true)
    Pkg.activate(env)
    own = parent_package(env)
    if (VERSION < v"1.11") && !isnothing(own)
        # Julia 1.10 ignores `[sources]`; URL sources are not applied here, see
        # `envcheck.jl apply-sources`.
        Pkg.develop(Pkg.PackageSpec(path = dirname(abspath(env))))
    end
    Pkg.instantiate()
    precompile && Pkg.precompile()
    Pkg.status()
end


function main(args)
    revert = "--revert" in args
    precompile = !("--no-precompile" in args)
    envs = filter(arg -> !startswith(arg, "--"), args)
    if isempty(envs)
        envs = filter(env -> isfile(joinpath(env, "Project.toml")), ["test", "docs"])
    end
    isempty(envs) && error("No environments found. Run from the root of a package checkout.")
    for env in envs
        if revert
            revertorg(env; precompile)
        else
            installorg(env; precompile)
        end
    end
end


if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
