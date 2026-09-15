# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contributing Guidelines

The organization-wide contributing guidelines apply to all repositories in this folder. Be sure to follow them when working with any of the packages. They also describe the development workflow and its design rationale:

@.github/CONTRIBUTING.md

**IMPORTANT:** If `.github/CONTRIBUTING.md` does not exist (i.e., the `@`-reference above failed to load its contents), you MUST stop and loudly warn the user.

## Development Environment Setup

This is the JuliaQuantumControl organization development environment - a meta-repository containing checkouts of multiple tightly coupled Julia packages for quantum control and dynamics.

### Initial Setup
- `make clone` - Clone all organization repositories into subfolders
- `make devrepl` - Start interactive REPL with the local checkouts of all packages

### Organization-wide Commands
- `make pull` - Pull latest changes from all repositories
- `make status` - Show git status for all checkouts
- `make testall` - Run `make test` for every package
- `make clean` - Clean build/doc/testing artifacts across all packages
- `make distclean` - Remove all auto-generated files
- `make check-circular-dependencies` - Validate dependency structure

## Package Structure

The organization contains these packages:

1. **QuantumPropagators.jl** - Core time propagation methods (Chebyshev, Newton, matrix exponential)
2. **QuantumGradientGenerators.jl** - Gradient computation utilities
3. **Krotov.jl** - Krotov optimization method
4. **GRAPE.jl** - GRAPE optimization method
5. **ParameterizedQuantumControl.jl** - Parameterized control optimization
6. **QuantumControl.jl** - High-level unified interface
7. **QuantumControlTestUtils.jl** - Random quantum objects for tests (standard-library dependencies only)
8. **GRAPELinesearchAnalysis.jl** - GRAPE linesearch analysis tools
9. **TwoQubitWeylChamber.jl** - Two-qubit gate analysis

### Individual Package Development

Each package has the same `Makefile`-based workflow (see `make help` and CONTRIBUTING.md):
- `make test` - Run the test suite in the package's `test` environment
- `make devrepl` - REPL with the `test` environment active and the `docs` environment stacked
- `make docs` - Build the documentation in the `docs` environment
- `make coverage` / `make htmlcoverage` - Test coverage
- `make codestyle` - Apply JuliaFormatter, check `CHANGELOG.md` and `[sources]`

## Key Development Files

- `scripts/envcheck.jl` - Lint and warnings for `[sources]`, Julia 1.10 helpers, lowest-compat pinning, held-back dependency check (used by package Makefiles and CI)
- `scripts/installorg.jl` - Switch a package's `test`/`docs` environments to local sibling checkouts (not used by default)
- `scripts/testall.jl` - Run `make test` across all packages
- `devrepl.jl` - Org-level development REPL setup script

## Special Notes

- Tests and docs use the **registered releases** of sibling packages by default, not the local checkouts
- A sibling can temporarily come from a GitHub branch via a URL `[sources]` entry in `test/Project.toml` or `docs/Project.toml`; CI warns about such entries
- Never commit a local `path` entry in `[sources]` (other than the package's own `{path = ".."}`); the codestyle CI job rejects it
- The `test` and `docs` environments are independent; packages do not use a Pkg workspace
- Local development uses Julia 1.13; the `make` targets require Julia >= 1.11 unless the `../scripts/envcheck.jl` helper is available (Julia 1.10)
