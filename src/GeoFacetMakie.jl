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

# Include submodules
include("structs.jl")
include("grid_operations.jl")
include("grid_loader.jl")
include("geofacet.jl")

end # module
