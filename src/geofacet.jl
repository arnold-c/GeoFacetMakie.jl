"""
Main geofacet plotting functionality for GeoFacetMakie.jl
"""

export geofacet, us_state_grid

"""
    us_state_grid

Predefined US state grid layout (includes Washington DC).

This is the standard US state grid layout from the geofacet R package,
providing a geographical arrangement of all 50 US states plus DC.

# Example
```julia
using GeoFacetMakie

# Use the predefined US state grid
geofacet(data, :state, plot_function; grid = us_state_grid)
```
"""
const us_state_grid = let
    try
        load_us_state_grid(1)
    catch e
        @warn "Could not load us_state_grid: $e"
        # Fallback to empty grid if loading fails
        GeoGrid(Dict{String, Tuple{Int, Int}}(), Dict{String, String}(), "us_state_grid1_fallback")
    end
end

# TODO: Implement geofacet function