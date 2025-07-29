"""
# GeoFacetMakie.jl

A Julia package for creating geofaceted visualizations using Makie.jl.
Inspired by the R geofacet package, this provides tools for arranging
plots in geographical layouts.

## Main Functions
- `geofacet`: Create geofaceted plots with custom geographical layouts
- `GeoGrid`: Define custom geographical grid layouts

## Example
```julia
using GeoFacetMakie, DataFrames

# Create a simple geofaceted plot
function plot_data(df, ax)
    lines!(ax, df.year, df.value)
end

geofacet(data, :state, plot_data; grid = us_state_grid)
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

end # module
