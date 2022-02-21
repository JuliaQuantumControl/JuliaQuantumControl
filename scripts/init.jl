using Pkg
using LocalRegistry
using JET
using Revise
using JuliaFormatter
using LiveServer: serve
using Plots
unicodeplots()
include(joinpath(@__DIR__, "clean.jl"))
include(joinpath(@__DIR__, "testall.jl"))
include(joinpath(@__DIR__, "gitutils.jl"))
include(joinpath(@__DIR__, "check_circular_deps.jl"))
include(joinpath(@__DIR__, "ctags.jl"))

REPL_MESSAGE = """
*******************************************************************************
DEVELOPMENT REPL for JuliaQuantumControl ORG

Revise, JET, JuliaFormatter, LiveServer, Plots with unicode backend are active.

* `help()` – Show this message
* `testall()` – Run the test suites of all projects, with coverage
* `create_tags()` – Create a `tags` (exuberant ctags) file for code navigation
* `testall(genhtml=true)` –
  Also write an HTML coverage report for every package.
* `include("QuantumControlBase.jl/test/runtests.jl")` –
  Run the test suite for `QuantumControlBase`. This may require a previous call
  to `testall()` to ensure that the subproject test environments are properly
  initialized.
* `include("QuantumControlBase.jl/devrepl.jl")` –
  Switch to a development REPL for `QuantumControlBase`. To switch back,
  include the org-`devrepl.jl` (`include("../devrepl.jl")`)
* `format(".")` – Apply code formatting to all files
* `serve(dir="QuantumControl.jl/docs/build" [port=8000, verbose=false])` –
  Serve the html files from the documentation build folder
* `check_circular_dependencies()` –
  Check all packages for circular dependencies
* `status()` – Show the git status for all projects
* run_all(`git log -n 1`) – Show last log entry for each project
* `register("./GRAPELinesearchAnalysis.jl", registry="QuantumControlRegistry")`
  – Release a new version of `GRAPELinesearchAnalysis` on the org registry.
* `clean()` – Clean up build/doc/testing artifacts across all projects
* `distclean()` – Restore to a clean checkout state across all projects

NOTE: Each org package also has its own "make devrepl"/`devrepl.jl` that may be
more convenient to use when working on that particular package. The devrepls
for the indvidual packages will also have access to the current checkout of all
org packages that they depend on.
*******************************************************************************
"""

"""Show help"""
help() = println(REPL_MESSAGE)

help()
