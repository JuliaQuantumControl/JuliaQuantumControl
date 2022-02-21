include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES

function create_tags()
    org_root = dirname(@__DIR__)
    folders = [joinpath(org_root, "$package.jl") for package in ORG_PACKAGES]
    src_folders = [joinpath(folder, "src") for folder in folders]
    options = joinpath(org_root, "julia.ctags")
    #=run(Cmd(["ctags", "-R", "--options=$options", src_folders...]))=#
    run(Cmd(["ctags", "-R", "--options=$options", "--languages=julia", src_folders...]))
end
