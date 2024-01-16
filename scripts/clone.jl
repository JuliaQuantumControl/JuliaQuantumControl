include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES
using LibGit2

function clone_org_repos()
    org_root = dirname(@__DIR__)
    repo = LibGit2.GitRepo(org_root)
    origin = LibGit2.lookup_remote(repo, "origin")
    devenv_url = LibGit2.url(origin)
    @assert devenv_url |> endswith("/JuliaQuantumControl.git")
    github_root = replace(devenv_url, r"/JuliaQuantumControl\.git" => "")
    for package in ORG_PACKAGES
        checkout = joinpath(org_root, "$package.jl")
        if isdir(checkout)
            @info "$checkout OK"
        else
            url = "$github_root/$package.jl.git"
            @info "Clone $url => $checkout"
            LibGit2.clone(url, checkout)
        end
    end
    package = "QuantumControlExamples"
    checkout = joinpath(org_root, "$package.jl")
    if isdir(checkout)
        @info "$checkout OK"
    else
        url = "$github_root/$package.jl.git"
        @info "Clone $url => $checkout"
        LibGit2.clone(url, checkout)
    end
    checkout = joinpath(org_root, ".github")
    if isdir(checkout)
        @info "$checkout OK"
    else
        url = "$github_root/.github.git"
        @info "Clone $url => $checkout"
        LibGit2.clone(url, checkout)
    end
end

clone_org_repos()
