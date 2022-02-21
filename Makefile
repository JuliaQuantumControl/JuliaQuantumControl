.PHONY: help clone pull devrepl clean testall distclean check-circular-dependencies tags
.DEFAULT_GOAL := help

JULIA ?= julia
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
	@$(JULIA) scripts/clone.jl

pull: ## Pull all org repositories
	@$(JULIA) -e 'include("scripts/gitutils.jl"); pull()'

status: ## Show git status for all checkouts
	@$(JULIA) -e 'include("scripts/gitutils.jl"); status()'

Manifest.toml:
	@$(JULIA) --project=. -e 'include("scripts/installorg.jl"); installorg()'

tags:  ## Generate a ctags file across all projects
	@$(JULIA) --project=. -e 'include("scripts/ctags.jl"); create_tags()'

devrepl: Manifest.toml ## Start an interactive REPL with the dev-version of all org repos
	@$(JULIA) --project=. --banner=no --startup-file=yes -i devrepl.jl

clean: ## Clean up build/doc/testing artifacts
	$(JULIA) -e 'include("scripts/clean.jl"); clean()'

testall: Manifest.toml  ## Run "make test" for all packages
	$(JULIA) --project=. -e 'include("scripts/testall.jl"); testall()'

check-circular-dependencies:  ## Check all projects for circular dependencies
	@$(JULIA) -e 'include("scripts/check_circular_deps.jl"); check_circular_dependencies()'

distclean: ## Remove all auto-generated files
	$(JULIA) -e 'include("scripts/clean.jl"); clean(distclean=true)'
