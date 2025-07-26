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

# Utility function exports
export grid_dimensions, validate_grid, has_region, get_position, get_region_at, get_regions, is_complete_rectangle

"""
    GeoGrid(name::String, positions::Dict{String, Tuple{Int, Int}})

A geographical grid layout that maps region names to grid positions.

# Arguments
- `name::String`: Name of the grid layout
- `positions::Dict{String, Tuple{Int, Int}}`: Mapping from region names to (row, col) positions

# Validation
- Region names cannot be empty or whitespace-only
- Grid positions must be positive integers (≥ 1)
- No two regions can occupy the same position

# Examples
```julia
# Create a simple 2x2 grid
grid = GeoGrid("test", Dict(
    "CA" => (1, 1), "NY" => (1, 2),
    "TX" => (2, 1), "FL" => (2, 2)
))
```
"""
struct GeoGrid
    name::String
    positions::Dict{String, Tuple{Int, Int}}
    
    function GeoGrid(name::String, positions::Dict{String, Tuple{Int, Int}})
        # Validate region names
        for region_name in keys(positions)
            if isempty(strip(region_name))
                throw(ArgumentError("Region names cannot be empty or whitespace-only"))
            end
        end
        
        # Validate positions are positive
        for (region, (row, col)) in positions
            if row <= 0 || col <= 0
                throw(ArgumentError("Grid positions must be positive integers (≥ 1), got ($row, $col) for region '$region'"))
            end
        end
        
        new(name, positions)
    end
end

"""
    grid_dimensions(grid::GeoGrid) -> Tuple{Int, Int}

Get the dimensions of a grid as (max_row, max_col).
Returns (0, 0) for empty grids.
"""
function grid_dimensions(grid::GeoGrid)
    if isempty(grid.positions)
        return (0, 0)
    end
    
    max_row = maximum(pos[1] for pos in values(grid.positions))
    max_col = maximum(pos[2] for pos in values(grid.positions))
    return (max_row, max_col)
end

"""
    validate_grid(grid::GeoGrid) -> Bool

Validate that no two regions occupy the same position.
Returns `true` if valid, throws `ArgumentError` if conflicts exist.
"""
function validate_grid(grid::GeoGrid)
    position_to_region = Dict{Tuple{Int, Int}, String}()
    
    for (region, position) in grid.positions
        if haskey(position_to_region, position)
            existing_region = position_to_region[position]
            throw(ArgumentError("Position conflict: regions '$existing_region' and '$region' both at position $position"))
        end
        position_to_region[position] = region
    end
    
    return true
end

"""
    has_region(grid::GeoGrid, region::String) -> Bool

Check if a region exists in the grid.
"""
function has_region(grid::GeoGrid, region::String)
    return haskey(grid.positions, region)
end

"""
    get_position(grid::GeoGrid, region::String) -> Union{Tuple{Int, Int}, Nothing}

Get the position of a region in the grid.
Returns `nothing` if the region doesn't exist.
"""
function get_position(grid::GeoGrid, region::String)
    return get(grid.positions, region, nothing)
end

"""
    get_region_at(grid::GeoGrid, row::Int, col::Int) -> Union{String, Nothing}

Get the region name at a specific grid position.
Returns `nothing` if no region exists at that position.
"""
function get_region_at(grid::GeoGrid, row::Int, col::Int)
    for (region, (r, c)) in grid.positions
        if r == row && c == col
            return region
        end
    end
    return nothing
end

"""
    get_regions(grid::GeoGrid) -> Vector{String}

Get all region names in the grid.
"""
function get_regions(grid::GeoGrid)
    return collect(keys(grid.positions))
end

"""
    is_complete_rectangle(grid::GeoGrid) -> Bool

Check if the grid forms a complete rectangle (no missing cells).
"""
function is_complete_rectangle(grid::GeoGrid)
    if isempty(grid.positions)
        return true  # Empty grid is technically complete
    end
    
    max_row, max_col = grid_dimensions(grid)
    expected_cells = max_row * max_col
    actual_cells = length(grid.positions)
    
    return expected_cells == actual_cells
end

end # module
