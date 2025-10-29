include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES

"""
    clean([distclean=false])

Clean up build/doc/testing artifacts for all org repos.
With `distclean=true`, restore to clean checkout state.
"""
function clean(; distclean = false, _exit = true)

    _exists(name) = isfile(name) || isdir(name)
    _push!(lst, name) = _exists(name) && push!(lst, name)
    _glob(folder, ending) =
        [name for name in readdir(folder; join = true) if (name |> endswith(ending))]

    ROOT = dirname(@__DIR__)

    ###########################################################################
    julia = Base.julia_cmd().exec[1]
    org_root = dirname(@__DIR__)
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        clean_jl = joinpath(pkg_root, "test", "clean.jl")
        if !isfile(clean_jl)
            clean_jl = joinpath(pkg_root, "clean.jl")
        end
        if !isfile(clean_jl)
            @error "$package does not have a clean.jl"
            continue
        end
        @info "== Clean $package =="
        run(
            Cmd([
                julia,
                "-e",
                "include(\"$clean_jl\"); clean(distclean=$distclean, _exit=false)"
            ])
        )
    end
    ###########################################################################

    ###########################################################################
    CLEAN = String[]
    append!(CLEAN, _glob(ROOT, ".info"))
    ###########################################################################

    ###########################################################################
    DISTCLEAN = String[]
    _push!(DISTCLEAN, joinpath(ROOT, "Manifest.toml"))
    _push!(DISTCLEAN, joinpath(ROOT, "tags"))
    ###########################################################################

    for name in CLEAN
        @info "rm $name"
        rm(name, force = true, recursive = true)
    end
    if distclean
        for name in DISTCLEAN
            @info "rm $name"
            rm(name, force = true, recursive = true)
        end
        if _exit
            @info "Exiting"
            exit(0)
        end
    end

end

distclean() = clean(distclean = true)
