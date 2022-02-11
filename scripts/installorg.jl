import Pkg

ORG_PACKAGES = [
    "QuantumPropagators",
    "QuantumControlBase",
    "Krotov",
    "GRAPE",
    "QuantumControl",
    "GRAPELinesearchAnalysis"
]


"""Return which one of ORG_PACKAGES we're currently in.

If the current package cannot be determined, return an empty string.
"""
function get_current_package()
    if "GITHUB_REPOSITORY" ∈ keys(ENV)
        reponame = split(ENV["GITHUB_REPOSITORY"], "/")[end]
    else
        git_root = find_git_root()
        reponame = basename(git_root)
    end
    @show reponame
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


"""Install dev-versions of all the projects in the JuliaQuantumControl org.

This dev-installs all packages in `ORG_PACKAGES` into the current environment.
"""
function installorg()
    Pkg.Registry.add(
        Pkg.RegistrySpec(
            url="https://github.com/JuliaQuantumControl/QuantumControlRegistry.git"
        )
    )
    current_package = get_current_package()
    @show current_package
    git_root = find_git_root()
    @show git_root
    for package in ORG_PACKAGES
        if package == current_package
            @info "Dev-install $package as current project from $git_root"
            Pkg.develop(path=git_root)
        else
            path_candidates = [
                joinpath(git_root, "$package.jl"),
                joinpath(dirname(git_root), "$package.jl"),
            ]
            installed = false
            for pkg_path ∈ path_candidates
                if isdir(pkg_path)
                    @info "Dev-install $package from $pkg_path"
                    Pkg.develop(path=pkg_path)
                    installed = true
                    break
                end
            end
            if !installed  # fallback
                @info "Dev-install $package from Github"
                Pkg.develop(package)
            end
        end
    end
    Pkg.instantiate()
end

if abspath(PROGRAM_FILE) == @__FILE__
    installorg()
end
