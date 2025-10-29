using QuantumControlTestUtils: test as _test
include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES


"""Run the full test-suite for all projects.

Keyword arguments are forwarded to `QuantumControlTestUtils.test`.
"""
function testall(; root = nothing, project = nothing, kwargs...)
    # `root` and `project` are just to capture those arguments from `kwargs`
    julia = Base.julia_cmd().exec[1]
    org_root = dirname(@__DIR__)
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        testenv = joinpath(pkg_root, "test")
        runtests_jl = joinpath(testenv, "runtests.jl")
        if isfile(runtests_jl)
            devrepl_jl = joinpath(pkg_root, "devrepl.jl")
            if isfile(devrepl_jl)
                if !isfile(joinpath(testenv, "Manifest.toml"))
                    @info "Initializing devrepl for $package"
                    run(`$julia $devrepl_jl`)
                end
                @info "Testing $package in its own test environment"
                _test(; root = pkg_root, project = testenv, kwargs...)
            else
                @info "Testing $package in org test environment"
                _test(; root = pkg_root, project = org_root, kwargs...)
            end
        else
            @warn "No tests for $package"
        end
    end
end
