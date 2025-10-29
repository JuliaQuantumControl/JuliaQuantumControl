import Pkg

# ORG_PACKAGES must be ordered by their internal dependencies: Later packages
# can depend on earlier ones, but not vice versa.
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

```julia
installorg(;github="add", localfolders=true, dependencies_only=true)
```

dev-installs packages from `ORG_PACKAGES` into the current environment. By
default, only packages explicitly listed as dependencies in the current
`Project.toml` will be installed. By setting `dependnecies_only=false`, *all*
packages in `ORG_PACKAGES` will be installed (which may modify `Project.toml`).

It is assumed that the organization has been set up with the clone.jl script.
That is, from the JuliaQuantumControl folder, the subprojects are in direct
subfolders, e.g. "QuantumControl.jl", and from the perspective of each
package, the sibling packages are in sibling folders.

Thus, the install scripts will check for the checkouts to dev-install as
subfolders of the JuliaQuantumControl repo containing this function (devrepl in
JuliaQuantumControl) or in a sibling folder (devrepl of a package). If neither
is available (e.g, when running on Github CI), or when `localfolders=false`, it
will install the master branch of any sibling package from Github. For
`github="add"`, this is done via `Pkg.add`, and for `github="develop"` via
`Pkg.develop`. Any other value (e.g.  `github=false`) prevents installation
from Github.
"""
function installorg(;github="add", localfolders=true, dependencies_only=true)
    Pkg.Registry.add(Pkg.RegistrySpec("General"))
    Pkg.Registry.add(
        Pkg.RegistrySpec(
            url="https://github.com/JuliaQuantumControl/QuantumControlRegistry.git"
        )
    )
    Pkg.Registry.update()
    project_toml = Pkg.project()
    current_package = get_current_package()
    git_root = find_git_root()
    if current_package == ""
        @info "No current package; CWD is $git_root"
    else
        @info "Current package is $current_package at $git_root"
    end
    # Counter-intuitively, we must dev-install packages in their reverse
    # dependency order. This is because Pkg always fully instantiates an
    # environment. In a project with dependencies A, B where B depends on A, if we
    # dev-install A, Pkg will try to also install B (from the registry!). This
    # will fail if the *released* B is incompatible with the dev-installed A.
    # However, if we dev-install B first, it will install a released version of
    # A, and then we can dev-install A to *overwrite* the released version, and
    # everything is OK
    for package in reverse(ORG_PACKAGES)
        if package == current_package
            current_relpath = relpath(git_root, pwd())
            # We use a relative path to avoid problems with `[sources]`.
            # See https://github.com/JuliaLang/Pkg.jl/issues/4426
            @info "Dev-install $package as current project from $git_root (relative path `$current_relpath`)"
            Pkg.develop(path=current_relpath)
        else
            if !(package in keys(project_toml.dependencies))
                if dependencies_only
                    @info "Skipping $package (not a project dependency)"
                    continue
                end
            end
            path_candidates = [
                joinpath(@__DIR__, "..", "$package.jl"),
                joinpath(git_root, "$package.jl"),
                joinpath(dirname(git_root), "$package.jl"),
            ]
            installed = false
            if localfolders
                for pkg_path ∈ path_candidates
                    if isdir(pkg_path)
                        @info "Dev-install $package from $pkg_path"
                        Pkg.develop(path=pkg_path)
                        installed = true
                        break
                    end
                end
            end
            if !installed  # fallback
                if github == "add"
                    @info "Add $package#master from Github"
                    Pkg.add(;url="https://github.com/JuliaQuantumControl/$package.jl", rev="master")
                elseif github == "develop"
                    @info "Dev-install $package from Github"
                    Pkg.develop(;url="https://github.com/JuliaQuantumControl/$package.jl")
                else
                    @error "$package could not be installed (github=false)"
                end
            end
        end
    end
    @info "Instantiate"
    Pkg.instantiate()
    @info "Precompile"
    Pkg.precompile()
    @info "Status"
    Pkg.status()
end

if abspath(PROGRAM_FILE) == @__FILE__
    installorg()
end
