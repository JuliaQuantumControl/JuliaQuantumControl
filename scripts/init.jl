using Pkg
using LocalRegistry
using Revise
using JuliaFormatter
using LiveServer: serve
using Plots
unicodeplots()
println("""
*******************************************************************************
DEVELOPMENT REPL for JuliaQuantumControl ORG

Revise, JuliaFormatter, LiveServer, Plots with unicode backend are active.

* `include("QuantumControlBase.jl/test/runtests.jl")` –
  Run the test suite for QuantumControlBase. This requires the
  QuantumControlBase test environment to be instantiated first (package devrepl)
* `format(".")` – Apply code formatting to all files
* `serve(dir="QuantumControl.jl/docs/build" [port=8000, verbose=false])` –
  Serve the html files from the documentation build folder

NOTE: Each org package also has its own "make devrepl"/`devrepl.jl` that may be
more convenient to use when working on that particular package. The devrepls
for the indvidual packages will also have access to the current checkout of all
org packages that they depend on.
*******************************************************************************
""")
