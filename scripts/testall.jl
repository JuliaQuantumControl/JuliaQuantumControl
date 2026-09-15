include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES


"""Run `make test` for all org packages that have a test suite.

```julia
testall(; target="test")
```

Each package is tested in its own `test` environment, exactly as with `make
test` in the package folder. That is, sibling packages are the registered
releases, or whatever is specified in `[sources]`. With `target="coverage"`,
run `make coverage` instead.
"""
function testall(; target = "test")
    org_root = dirname(@__DIR__)
    failed = String[]
    for package in ORG_PACKAGES
        pkg_root = joinpath(org_root, "$package.jl")
        if isfile(joinpath(pkg_root, "test", "runtests.jl"))
            @info "Testing $package"
            if !success(run(ignorestatus(`make -C $pkg_root $target`)))
                push!(failed, package)
            end
        else
            @warn "No tests for $package"
        end
    end
    if isempty(failed)
        @info "All tests passed"
    else
        error("Tests failed for: $(join(failed, ", "))")
    end
end
