using Pkg
using Revise
using JuliaFormatter
using LiveServer: serve
using Plots
using Term

unicodeplots()

include(joinpath(@__DIR__, "clean.jl"))
include(joinpath(@__DIR__, "testall.jl"))
include(joinpath(@__DIR__, "gitutils.jl"))
include(joinpath(@__DIR__, "check_circular_deps.jl"))
include(joinpath(@__DIR__, "ctags.jl"))


REPL_MESSAGE = """
*******************************************************************************
DEVELOPMENT REPL for JuliaQuantumControl ORG

Revise, JuliaFormatter, LiveServer, Plots with unicode backend are active. All
org packages are the local checkouts.

* `help()` – Show this message
* `testall()` – Run `make test` for all packages. Each package is tested in its
  own `test` environment, with registered sibling packages (or `[sources]`)
* `testall(target="coverage")` – Run `make coverage` for all packages
* `create_tags()` – Create a `tags` (exuberant ctags) file for code navigation
* `format(".")` – Apply code formatting to all files
* `serve(dir="QuantumControl.jl/docs/build" [port=8000, verbose=false])` –
  Serve the html files from the documentation build folder
* `check_circular_dependencies()` –
  Check all packages for circular dependencies
* `status()` – Show the git status for all projects
* run_all(`git log -n 1`) – Show last log entry for each project
* `clean()` – Clean up build/doc/testing artifacts across all projects
* `distclean()` – Restore to a clean checkout state across all projects

NOTE: Each org package also has its own `make devrepl` that is more convenient
when working on that particular package. See CONTRIBUTING.md.
*******************************************************************************
"""

"""Show help"""
help() = println(REPL_MESSAGE)

help()
