# Checks and helpers for the `test` and `docs` environments of packages in the
# JuliaQuantumControl organization. Used by CI and by the package Makefiles.
#
# Run from the root of a package checkout as
#
#     julia envcheck.jl COMMAND [ARGS...]
#
# Commands:
#
# * `lint [--no-remote]` – Check that `[sources]` follow the org policy (see
#   CONTRIBUTING.md). With `--no-remote`, do not check that a `rev` exists on
#   the remote.
# * `warn-sources [ENV...]` – Emit a warning for every sibling package taken
#   from a `[sources]` entry instead of its registered release, and for every
#   such sibling that the package's `[compat]` requires in an unregistered
#   version. `ENV` defaults to `test` and `docs`.
# * `apply-sources ENV` – Apply the `[sources]` of the environment with
#   `Pkg.develop`/`Pkg.add`. Only has an effect on Julia < 1.11, which ignores
#   `[sources]`.
# * `pin-lowest ENV LOWEST_MANIFEST` – Re-resolve the environment with the
#   dependencies of the package pinned to the versions in `LOWEST_MANIFEST` (as
#   written by `julia-actions/julia-downgrade-compat`).
# * `held-back ENV` – Emit a warning for every dependency of the package that
#   the environment holds back below the newest version the package's
#   `[compat]` allows.
#
# The script has no dependencies outside the Julia standard library.

import Pkg
import TOML

const ON_CI = get(ENV, "GITHUB_ACTIONS", "false") == "true"


function annotate(level, msg; file = nothing, title = nothing)
    if ON_CI
        props = String[]
        isnothing(file) || push!(props, "file=$file")
        isnothing(title) || push!(props, "title=$title")
        props_str = isempty(props) ? "" : " " * join(props, ",")
        println("::$level$props_str::", replace(msg, "\n" => "%0A"))
    else
        prefix = isnothing(file) ? "" : "$file: "
        if level == "error"
            @error prefix * msg
        elseif level == "warning"
            @warn prefix * msg
        else
            @info prefix * msg
        end
    end
end


function read_toml(file)
    return isfile(file) ? TOML.parsefile(file) : nothing
end


function package_name()
    project = read_toml("Project.toml")
    if isnothing(project) || !haskey(project, "name")
        error("No package Project.toml found. Run envcheck.jl from the root of a package checkout.")
    end
    return project["name"]
end


# The environments in which `[sources]` are allowed
const SUBENVS = ["test", "docs"]


"""Return a list of problems with `rev` for the repository at `url`."""
function check_remote_rev(url, rev)
    # For a nonexistent GitHub repository, git asks for credentials instead of
    # failing. Disable all credential prompts and helpers, and time out as a
    # last resort.
    cmd = addenv(
        `git -c credential.helper= ls-remote --heads --tags $url $rev`,
        "GIT_TERMINAL_PROMPT" => "0",
        "GIT_ASKPASS" => "",
        "SSH_ASKPASS" => "",
    )
    buffer = IOBuffer()
    process = run(pipeline(ignorestatus(cmd); stdout = buffer, stderr = devnull); wait = false)
    timer = Timer(60) do _
        process_running(process) && kill(process)
    end
    wait(process)
    close(timer)
    if !success(process)
        return ["Cannot find $url (or no access to it)"]
    end
    output = String(take!(buffer))
    refs = [split(line)[end] for line in split(output, "\n") if !isempty(strip(line))]
    if ("refs/heads/$rev" in refs) || ("refs/tags/$rev" in refs)
        return String[]
    else
        return ["`rev = \"$rev\"` is not an existing branch or tag of $url"]
    end
end


function lint(; remote = true)
    name = package_name()
    n_errors = 0
    function report(file, msg)
        annotate("error", msg; file, title = "Invalid [sources]")
        n_errors += 1
    end
    root = read_toml("Project.toml")
    if haskey(root, "sources")
        report(
            "Project.toml",
            "The package Project.toml must not have a [sources] section. Sources in a package's Project.toml would apply to every environment that develops the package (Julia ≥ 1.13). Put them in test/Project.toml or docs/Project.toml instead."
        )
    end
    if haskey(root, "workspace")
        report(
            "Project.toml",
            "The package Project.toml must not have a [workspace] section. The test and docs environments are deliberately independent. See CONTRIBUTING.md."
        )
    end
    for env in SUBENVS
        file = joinpath(env, "Project.toml")
        project = read_toml(file)
        isnothing(project) && continue
        deps = get(project, "deps", Dict())
        extras = get(project, "extras", Dict())
        sources = get(project, "sources", Dict())
        if haskey(deps, name) && (get(sources, name, nothing) != Dict("path" => ".."))
            report(file, "Must have `$name = {path = \"..\"}` in [sources].")
        end
        for pkg in sort(collect(keys(sources)))
            source = sources[pkg]
            pkg == name && continue
            if !(haskey(deps, pkg) || haskey(extras, pkg))
                report(file, "[sources] entry for $pkg, which is not in [deps].")
            end
            if haskey(source, "path")
                report(
                    file,
                    "Local path `$(source["path"])` in [sources] entry for $pkg. Only URL sources (`$pkg = {url = \"https://github.com/JuliaQuantumControl/$pkg.jl\", rev = \"<branch>\"}`) may be committed. Did you commit a change made by installorg.jl?"
                )
                continue
            end
            unknown = setdiff(keys(source), ["url", "rev"])
            if !isempty(unknown)
                report(file, "Unsupported keys $(collect(unknown)) in [sources] entry for $pkg.")
            end
            url = get(source, "url", nothing)
            rev = get(source, "rev", nothing)
            if isnothing(url)
                report(file, "[sources] entry for $pkg must have a `url`.")
                continue
            end
            if isnothing(match(Regex("^https://github\\.com/[^/]+/$pkg\\.jl(\\.git)?/?\$"), url))
                report(
                    file,
                    "The `url` of the [sources] entry for $pkg must be a GitHub repository https://github.com/<owner>/$pkg.jl, not `$url`."
                )
            end
            if isnothing(rev)
                report(file, "[sources] entry for $pkg must specify the branch as `rev`.")
            elseif remote
                for msg in check_remote_rev(url, rev)
                    report(file, msg)
                end
            end
        end
    end
    if n_errors == 0
        println("[sources] OK")
    end
    return n_errors == 0
end


function sibling_sources(env)
    name = package_name()
    project = read_toml(joinpath(env, "Project.toml"))
    isnothing(project) && return Dict{String,Any}()
    sources = get(project, "sources", Dict{String,Any}())
    return Dict(pkg => source for (pkg, source) in sources if pkg != name)
end


function describe_source(source)
    if haskey(source, "url")
        return string(source["url"], "#", get(source, "rev", "<default branch>"))
    else
        return string("path ", get(source, "path", "?"))
    end
end


"""Return the registered versions of the package `uuid` that are not yanked."""
function registered_versions(uuid)
    versions = Set{VersionNumber}()
    for registry in Pkg.Registry.reachable_registries()
        entry = get(registry.pkgs, uuid, nothing)
        isnothing(entry) && continue
        # Older versions of Julia have only the single-argument `registry_info`
        info = if applicable(Pkg.Registry.registry_info, registry, entry)
            Pkg.Registry.registry_info(registry, entry)
        else
            Pkg.Registry.registry_info(entry)
        end
        for (version, version_info) in info.version_info
            version_info.yanked || push!(versions, version)
        end
    end
    return versions
end


function warn_sources(envs)
    root = read_toml("Project.toml")
    root_deps = merge(get(root, "deps", Dict()), get(root, "weakdeps", Dict()))
    root_compat = get(root, "compat", Dict())
    registries_updated = false
    checked_compat = Set{String}()
    for env in envs
        file = joinpath(env, "Project.toml")
        isfile(file) || continue
        sources = sibling_sources(env)
        if isempty(sources)
            println("$file: all sibling packages are registered releases")
        end
        for pkg in sort(collect(keys(sources)))
            annotate(
                "warning",
                "$pkg is taken from $(describe_source(sources[pkg])) instead of its registered release. Remove the [sources] entry as soon as possible.";
                file,
                title = "Unreleased sibling package"
            )
            (haskey(root_deps, pkg) && haskey(root_compat, pkg)) || continue
            (pkg in checked_compat) && continue
            push!(checked_compat, pkg)
            if !registries_updated
                # A missing or stale registry would report a registered version
                # as unregistered. `Pkg.Registry.update` does not install a
                # registry in a new depot (e.g., on CI).
                if isempty(Pkg.Registry.reachable_registries())
                    Pkg.Registry.add("General")
                else
                    Pkg.Registry.update()
                end
                registries_updated = true
            end
            spec = Pkg.Versions.semver_spec(root_compat[pkg])
            if !any(in(spec), registered_versions(Base.UUID(root_deps[pkg])))
                annotate(
                    "warning",
                    "The [compat] entry `$pkg = \"$(root_compat[pkg])\"` excludes all registered versions of $pkg. Until a compatible version of $pkg is registered, running the tests with `Pkg.test` (the Test job) and the lowest-compat job fail with \"Unsatisfiable requirements\" for $pkg: both resolve the dependencies of the package without the [sources] of the $env environment.";
                    file = "Project.toml",
                    title = "Unregistered sibling version"
                )
            end
        end
    end
    return true
end


"""Return true if the active environment tracks `uuid` by path."""
function tracks_path(uuid)
    # `Pkg.dependencies()` throws if the environment is not instantiated
    info = try
        get(Pkg.dependencies(), uuid, nothing)
    catch
        nothing
    end
    return !isnothing(info) && info.is_tracking_path
end


function apply_sources(env)
    if VERSION >= v"1.11"
        println("Julia $VERSION applies [sources] natively")
        return true
    end
    name = package_name()
    project = read_toml(joinpath(env, "Project.toml"))
    sources = get(project, "sources", Dict())
    Pkg.activate(env)
    url_specs = Pkg.PackageSpec[]
    path_specs = Pkg.PackageSpec[]
    for pkg in sort(collect(keys(sources)))
        source = sources[pkg]
        if haskey(source, "url")
            push!(url_specs, Pkg.PackageSpec(; name = pkg, url = source["url"], rev = get(source, "rev", nothing)))
        elseif haskey(source, "path")
            uuid = Base.UUID(project["deps"][pkg])
            if !tracks_path(uuid)
                push!(path_specs, Pkg.PackageSpec(; path = normpath(joinpath(env, source["path"]))))
            end
        end
    end
    isempty(url_specs) || Pkg.add(url_specs)
    isempty(path_specs) || Pkg.develop(path_specs)
    return true
end


function pin_lowest(env, lowest_manifest)
    project = read_toml("Project.toml")
    names = union(keys(get(project, "deps", Dict())), keys(get(project, "weakdeps", Dict())))
    lowest = get(read_toml(lowest_manifest), "deps", Dict())
    specs = Pkg.PackageSpec[]
    for name in sort(collect(names))
        haskey(lowest, name) || continue
        entry = only(lowest[name])
        # Skip standard libraries and packages from `[sources]`: only registered
        # packages have a `git-tree-sha1` without a `path` or `repo-url`.
        haskey(entry, "git-tree-sha1") || continue
        (haskey(entry, "path") || haskey(entry, "repo-url")) && continue
        push!(specs, Pkg.PackageSpec(; name, version = VersionNumber(entry["version"])))
    end
    # The lowest manifest also floors the test-only dependencies (including
    # sibling packages), which may be incompatible with the package or its tests.
    # Resolve the environment from scratch, with only the dependencies of the
    # package pinned to their lowest versions.
    rm(joinpath(env, "Manifest.toml"); force = true)
    apply_sources(env)  # Julia < 1.11 ignores `[sources]`
    Pkg.activate(env)
    if isempty(specs)
        Pkg.resolve()
    else
        Pkg.add(specs)
    end
    Pkg.instantiate()
    Pkg.status(; mode = Pkg.PKGMODE_MANIFEST)
    return true
end


function held_back(env)
    name = package_name()
    project = read_toml("Project.toml")
    names = union(keys(get(project, "deps", Dict())), keys(get(project, "weakdeps", Dict())))
    Pkg.activate(env)
    # On CI, `julia-runtest` tests in a temporary environment, so the `env`
    # environment may not have been instantiated yet
    Pkg.instantiate()
    io = IOBuffer()
    Pkg.status(; outdated = true, mode = Pkg.PKGMODE_MANIFEST, io)
    status = String(take!(io))
    print(status)
    # Lines look like
    #   ⌅ [a759f4b9] TimerOutputs v0.5.29 (<v1.2.2): QuantumControlTestUtils
    #   ⌅ [98e50ef6] JuliaFormatter v2.3.0 (<v2.14.0) [compat]
    # where the packages after the colon (or `[compat]` for the environment's
    # own compat bounds) prevent the upgrade.
    rx = r"^\s*⌅\s+\[[0-9a-f]+\]\s+(\S+)\s+v(\S+)\s+\(<v([^)]+)\)\s*(.*)$"
    n_held_back = 0
    for line in split(status, "\n")
        m = match(rx, line)
        isnothing(m) && continue
        pkg, version, newest, rest = m.captures
        pkg in names || continue
        holders = strip.(split(replace(strip(rest), r"^:" => ""), ","))
        holders = filter(h -> !isempty(h) && (h != name), holders)
        isempty(holders) && continue  # held back by the package's own [compat]
        annotate(
            "warning",
            "$pkg is held back at v$version (newest: v$newest) by $(join(holders, ", ")) in the $env environment, so the newest version allowed by the $name [compat] is not tested.";
            file = joinpath(env, "Project.toml"),
            title = "Held-back dependency"
        )
        n_held_back += 1
    end
    if n_held_back == 0
        println("No dependencies of $name are held back in the $env environment")
    end
    return true
end


function main(args)
    isempty(args) && error("Usage: julia envcheck.jl COMMAND [ARGS...]")
    command = args[1]
    rest = args[2:end]
    ok = if command == "lint"
        lint(; remote = !("--no-remote" in rest))
    elseif command == "warn-sources"
        warn_sources(isempty(rest) ? SUBENVS : rest)
    elseif command == "apply-sources"
        apply_sources(only(rest))
    elseif command == "pin-lowest"
        pin_lowest(rest[1], rest[2])
    elseif command == "held-back"
        held_back(only(rest))
    else
        error("Unknown command $command")
    end
    exit(ok ? 0 : 1)
end


if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
