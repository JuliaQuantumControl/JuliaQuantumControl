using Pkg
using LocalRegistry
using Revise
using JuliaFormatter
using Plots
unicodeplots()
println("""
*******************************************************************************
DEVELOPMENT REPL for JuliaQuantumControl ORG

Revise is active.

JuliaFormatter is active (use `format` function)

Plots is active with backend UnicodePlots

Run e.g.

    include("QuantumControlBase.jl/test/runtests.jl")

for running the test suite for an org-package.

NOTE: Each org package also has its own "make devrepl" that may be more
convenient to use when working on that particular package. The devrepls
for the indvidual packages will also have access to the current checkout
of all org packages that they depend on.
*******************************************************************************
""")
