include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES


"""Run `make clean` (or `make distclean`) for all org packages.

```julia
clean(; distclean=false, _exit=true)
```

With `distclean=true`, also remove the `Manifest.toml` and `tags` file of the
development environment and exit (unless `_exit=false`), since the active
environment is no longer valid.
"""
function clean(; distclean = false, _exit = true)
    org_root = dirname(@__DIR__)
    target = distclean ? "distclean" : "clean"
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        if isfile(joinpath(pkg_root, "Makefile"))
            @info "make $target in $package.jl"
            run(ignorestatus(`make -C $pkg_root $target`))
        end
    end
    if distclean
        for name in ["Manifest.toml", "tags"]
            file = joinpath(org_root, name)
            if isfile(file)
                @info "rm $file"
                rm(file)
            end
        end
        if _exit
            @info "Exiting"
            exit(0)
        end
    end
end

distclean() = clean(distclean = true)
