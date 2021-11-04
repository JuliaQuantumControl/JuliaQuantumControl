# include this file from any Julia REPL to install the dev-versions of all
# packages into that REPL's environment

packages = ["QuantumPropagators", "QuantumControlBase", "Krotov", "GRAPE",
            "QuantumControl", "GRAPELinesearchAnalysis"]

import Pkg
for package in packages
    println("Installing $package")
    Pkg.develop(path=joinpath(@__DIR__, "..", "$package.jl"))
end
