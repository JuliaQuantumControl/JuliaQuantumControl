.PHONY: help clone pull devrepl clean testall distclean check-circular-dependencies
.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
    match = re.match(r'^([a-z0-9A-Z_-]+):.*?## (.*)$$', line)
    if match:
        target, help = match.groups()
        print("%-20s %s" % (target, help))
print("""

Consider using a long-running Julia REPL for repeated tasks.
""")
endef
export PRINT_HELP_PYSCRIPT

define INIT_JL
using Pkg
Pkg.activate(".")
using Revise
println("""
*******************************************************************************
DEVELOPMENT REPL for JuliaQuantumControl ORG

Revise is active

Run e.g.

    Pkg.test("QuantumControlBase")

for running the test suite for an org-package.

NOTE: Each org package also has its own "make devrepl" that may be more
convenient to use when working on that particular package. The devrepls
for the indvidual packages will also have access to the current checkout
of all org packages that they depend on.
*******************************************************************************
""")
endef
export INIT_JL

REMOTEROOT = git@github.com:JuliaQuantumControl
ORGPKGS = QuantumPropagators QuantumControlBase Krotov GRAPE QuantumControl

define CHECK_CIRCULAR_DEPS_JL
using TOML
folders = filter(x->isdir(x) && endswith(x, ".jl"), readdir("."))
dependencies = Dict(chop(f, tail=3) => keys(TOML.parsefile(joinpath(f, "Project.toml"))["deps"]) for f in folders)
print("dependencies = ")
display(dependencies)
println("")
ok = true
for project in keys(dependencies)
    for dep in dependencies[project]
        if project in get(dependencies, dep, [])
		    println("ERROR: $$project and $$dep have a circular dependency")
			global ok = false
        end
    end
end
ok && println("OK")
endef
export CHECK_CIRCULAR_DEPS_JL


help:  ## show this help
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)


clone: ## Clone all org repositories
	@for pkg in $(ORGPKGS); do echo "\n=======\n$$pkg"; if [ ! -d "$$pkg.jl" ]; then git clone "$(REMOTEROOT)/$$pkg.jl.git"; else echo "OK"; fi; done

pull: ## Pull all org repositories
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; git remote update -p; git merge --ff-only @{u}); done

status: ## Show git status for all checkouts
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; git status); done

Manifest.toml:
	@for folder in *.jl; do julia --project=. -e "using Pkg; Pkg.develop(PackageSpec(path=\"$$folder\"))"; done

devrepl: Manifest.toml ## Start an interactive REPL with the dev-version of all org repos
	@julia --threads auto --project=test --banner=no --startup-file=yes -e "$$INIT_JL" -i

clean: ## Clean up build/doc/testing artifacts
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; make clean); done

testall: ## Run "make test" for all packages
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; make test); done

check-circular-dependencies:  ## Check all projects for circular dependencies
	@julia -e "$$CHECK_CIRCULAR_DEPS_JL"

distclean: ## Remove all auto-generated files
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; make distclean); done
	@echo "\n=======\nORG devrepl toml-files"
	rm -f Project.toml
	rm -f Manifest.toml
