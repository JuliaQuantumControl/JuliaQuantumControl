# Source this script as e.g.
#
#     include("PATH/TO/devrepl.jl")
#
# from *any* Julia REPL or run it as e.g.
#
#     julia -i --banner=no PATH/TO/devrepl.jl
#
# from anywhere. This will change the current working directory and
# activate/initialize the correct Julia environment for you.
#
# You may also run this in vscode to initialize a development REPL
#
using Pkg

cd(@__DIR__)
Pkg.activate(".")
if !isfile("Manifest.toml")
    include("scripts/installorg.jl")
    installorg()
end
include("scripts/init.jl")
