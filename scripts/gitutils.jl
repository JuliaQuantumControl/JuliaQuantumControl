include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES

"""Run `git status` for all projects. """
function status()
    org_root = dirname(@__DIR__)
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        @info "$package ($pkg_root) git status"
        run(Cmd(`git status -s`, dir=pkg_root))
    end
end


"""Run `git pull` (ff-only) for all projects."""
function pull()
    org_root = dirname(@__DIR__)
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        @info "Pulling $package ($pkg_root)"
        run(Cmd(`git remote update -p`, dir=pkg_root))
        run(Cmd(Cmd(["git", "merge", "--ff-only", "@{u}"]), dir=pkg_root))
    end
end


"""Run `cmd` in all projects.

```julia
run_all(cmd; kwargs...)
```

if equivalent to `run(cmd; kwargs...)` in each project folder. Any `dir`
argument is relative to the project folder.
"""
function run_all(cmd; dir="", kwargs...)
    org_root = dirname(@__DIR__)
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        @info "== $package.jl> $cmd"
        run(Cmd(cmd; dir=joinpath(pkg_root, dir), kwargs...))
    end
end
