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


"""Install dev-versions of all the projects in the JuliaQuantumControl org.

This dev-installs all packages in `ORG_PACKAGES` into the current environment.

It is assumed that the organization has been set up with the clone.jl script.
That is, from the JuliaQuantumControl folder, the subprojects are in direct
subfolders, e.g. "QuantumControlBase.jl", and from the perspective of each
package, the sibling packages are in sibling folders.

Thus, the install scripts will check for the checkouts to dev-install as
subfolders of the current folder (devrepl in JuliaQuantumControl) or in a
sibling folder (devrepl of a package). If neither is available (e.g, when
running on Github CI), it will install the master branch of any sibling package
from Github.
"""
function installorg()
    Pkg.Registry.add(Pkg.RegistrySpec("General"))
    Pkg.Registry.add(
        Pkg.RegistrySpec(
            url="https://github.com/JuliaQuantumControl/QuantumControlRegistry.git"
        )
    )
    current_package = get_current_package()
    git_root = find_git_root()
    if current_package == ""
        @info "No current package; CWD is $git_root"
    else
        @info "Current package is $current_package at $git_root"
    end
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
