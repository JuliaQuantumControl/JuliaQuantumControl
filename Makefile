.PHONY: help clone pull devrepl clean testall distclean check-circular-dependencies
.DEFAULT_GOAL := help

define PRINT_HELP_JLSCRIPT
rx = r"^([a-z0-9A-Z_-]+):.*?##[ ]+(.*)$$"
for line in eachline()
    m = match(rx, line)
    if !isnothing(m)
        target, help = m.captures
        println("$$(rpad(target, 20)) $$help")
    end
end
endef
export PRINT_HELP_JLSCRIPT

help:  ## show this help
	@julia -e "$$PRINT_HELP_JLSCRIPT" < $(MAKEFILE_LIST)

clone: ## Clone all org repositories
	@julia scripts/clone.jl

pull: ## Pull all org repositories
	@for folder in .github *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; git remote update -p; git merge --ff-only @{u}); done

status: ## Show git status for all checkouts
	@for folder in .github *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; git status); done

Manifest.toml:
	@julia --project=. -e 'include("scripts/installorg.jl"); installorg()'

devrepl: Manifest.toml ## Start an interactive REPL with the dev-version of all org repos
	@julia --project=. --banner=no --startup-file=yes -i devrepl.jl

clean: ## Clean up build/doc/testing artifacts
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; make clean); done

testall: ## Run "make test" for all packages
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; make test); done

check-circular-dependencies:  ## Check all projects for circular dependencies
	@julia scripts/check_circular_deps.jl

distclean: ## Remove all auto-generated files
	@for folder in *.jl; do echo "\n=======\n$$folder"; (cd "$$folder"; make distclean); done
	@echo "\n=======\nORG devrepl toml-files"
	rm -f Manifest.toml
