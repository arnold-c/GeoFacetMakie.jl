# AGENTS.md - Development Guidelines for GeoFacetMakie.jl

## Build/Test Commands
- **Run all tests**: `julia --project=. -e "using Pkg; Pkg.test()"`
- **Run single test file**: `julia --project=. test/test_geofacet.jl`
- **Format code**: `julia -e "using Runic; Runic.main([\"src/\", \"test/\"])"`
- **Type checking**: Enable JET tests in `test/runtests.jl` (currently commented out)

## Code Style & Conventions
- **Formatting**: Use Runic.jl for consistent formatting (enforced in CI)
- **Imports**: Group standard library, then external packages, then local modules
- **Types**: Use concrete types in function signatures, abstract types for flexibility
- **Naming**: snake_case for functions/variables, PascalCase for types, UPPER_CASE for constants
- **Documentation**: Use docstrings with examples for all exported functions
- **Error handling**: Use Try.jl for operations that may fail, provide meaningful error messages

## Testing
- All tests in `test/` directory, organized by functionality
- Use `@testset` blocks for grouping related tests
- Include both positive and edge case testing
- JET.jl for static analysis (re-enable when core functionality complete)
- Aqua.jl for package quality assurance

## Dependencies
- Core: Makie.jl, DataFrames.jl, CSV.jl for data handling
- Testing: Test.jl, JET.jl, Aqua.jl
- Julia ≥ 1.10 required

## Architecture & Design
See DESIGN.md for comprehensive architecture overview including:
- Core data structures (GeoGrid, GeoFacetSpec)
- Function-passing API design with user-defined plotting functions
- Makie GridLayout integration strategy
- DataFrames.jl grouping and coordination patterns
- Implementation phases and technical considerations
