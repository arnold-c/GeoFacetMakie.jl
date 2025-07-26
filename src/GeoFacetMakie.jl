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

# Core exports
export geofacet, GeoGrid

# Grid exports  
export us_state_grid

end # module
