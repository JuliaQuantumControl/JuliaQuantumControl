using TOML

include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES

"""Check packages for circular dependencies."""
function check_circular_dependencies()
    org_root = dirname(@__DIR__)
    dependencies = Dict(
        package => keys(TOML.parsefile(joinpath(org_root, "$package.jl", "Project.toml"))["deps"]) for
        package in ORG_PACKAGES
    )
    ok = true
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        for dep in dependencies[package]
            if package in get(dependencies, dep, [])
                @error "$package and $dep have a circular dependency"
                ok = false
            end
        end
    end
    ok && println("OK")
end
