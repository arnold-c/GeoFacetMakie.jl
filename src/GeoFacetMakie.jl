"""
# GeoFacetMakie.jl

A Julia package for creating geofaceted visualizations using Makie.jl.
Inspired by the R geofacet package, this provides tools for arranging
plots in geographical layouts.

## Main Functions
- `geofacet`: Create geofaceted plots with custom geographical layouts
- `GeoGrid`: Define custom geographical grid layouts
- `load_grid_from_csv`: Load predefined grid layouts from CSV files

## Example
```julia
using GeoFacetMakie, DataFrames

# Create sample data
data = DataFrame(
    state = ["CA", "TX", "NY"],
    year = [2020, 2020, 2020],
    value = [100, 85, 95]
)

# Create a simple geofaceted plot
geofacet(data, :state, (gl, data; kwargs...) -> begin
    ax = Axis(gl[1, 1]; kwargs...)
    lines!(ax, data.year, data.value)
    ax.title = data.state[1]
end; grid = us_state_grid1)
```
"""
module GeoFacetMakie

using Makie
using DataFrames
using StructArrays

# Re-export StructArrays for test convenience
export StructArrays

# Include type definitions
include("types/grid_entry.jl")
include("types/geo_grid.jl")

# Include core functionality
include("grid_utils/grid_operations.jl")
include("grid_utils/grid_loader.jl")

# Include plotting functionality
include("plotting/data_processing.jl")
include("plotting/axis_management.jl")
include("plotting/geofacet_core.jl")

# Include predefined grids
include("data/predefined_grids.jl")

# Include documentation files (attach docstrings to functions)
include("docs/types_docs.jl")
include("docs/grid_operations_docs.jl")
include("docs/grid_loader_docs.jl")
include("docs/geofacet_docs.jl")
include("docs/internal_docs.jl")

end # module
