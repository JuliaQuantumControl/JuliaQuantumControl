# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment Setup

This is the JuliaQuantumControl organization development environment - a meta-repository containing multiple tightly coupled Julia packages for quantum control and dynamics.

### Initial Setup
- `make clone` - Clone all organization repositories into subfolders
- `make devrepl` - Start interactive REPL with development versions of all packages

### Organization-wide Commands
- `make pull` - Pull latest changes from all repositories
- `make status` - Show git status for all checkouts
- `make testall` - Run complete test suite across all packages
- `make clean` - Clean build/doc/testing artifacts across all packages
- `make distclean` - Remove all auto-generated files
- `make check-circular-dependencies` - Validate dependency structure

## Package Structure

The organization contains these packages in dependency order:

1. **QuantumPropagators.jl** - Core time propagation methods (Chebyshev, Newton, matrix exponential)
2. **QuantumGradientGenerators.jl** - Gradient computation utilities
3. **Krotov.jl** - Krotov optimization method
4. **GRAPE.jl** - GRAPE optimization method
5. **ParameterizedQuantumControl.jl** - Parameterized control optimization
6. **QuantumControl.jl** - High-level unified interface
7. **QuantumControlTestUtils.jl** - Testing utilities
8. **GRAPELinesearchAnalysis.jl** - GRAPE linesearch analysis tools
9. **TwoQubitWeylChamber.jl** - Two-qubit gate analysis

### Individual Package Development

Each package has its own development environment:
- `cd PackageName.jl && make devrepl` - Package-specific development REPL
- `make test` - Run package tests with coverage
- `make docs` - Build package documentation
- `make codestyle` - Apply JuliaFormatter

## Key Development Files

- `devrepl.jl` - Development REPL setup script (org-level and per-package)
- `scripts/installorg.jl` - Manages development dependencies across packages
- `scripts/testall.jl` - Orchestrates testing across all packages
- Each package Makefile includes standard targets: test, docs, devrepl, codestyle, clean, distclean

## Architecture Highlights

**QuantumControl Ecosystem:**
- Unified API through QuantumControl.jl with re-exported submodules
- Modular propagation methods in QuantumPropagators.jl
- Extensible optimization framework supporting multiple methods
- Interface-driven design with validation for operators, states, generators

**Development Workflow:**
- All packages developed simultaneously using dev versions of siblings
- Sophisticated dependency management via scripts/installorg.jl
- SafeTestsets for isolated testing
- Comprehensive documentation with Documenter.jl

## Special Notes

- Testing automatically uses current dev versions of all sibling packages
- Package order in ORG_PACKAGES (scripts/installorg.jl) reflects dependency structure
- Use the QuantumControlRegistry for managing unregistered package versions
