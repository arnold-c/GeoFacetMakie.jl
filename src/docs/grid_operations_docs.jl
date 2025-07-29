"""
Documentation for GeoFacetMakie.jl grid operations
"""

@doc """
    grid_dimensions(grid::GeoGrid) -> Tuple{Int, Int}

Get the dimensions of a grid as (max_row, max_col).
Returns (0, 0) for empty grids.
""" grid_dimensions

@doc """
    validate_grid(grid::GeoGrid) -> Bool

Validate that no two regions occupy the same position.
Returns `true` if valid, throws `ArgumentError` if conflicts exist.
""" validate_grid

@doc """
    has_region(grid::GeoGrid, region::String) -> Bool

Check if a region exists in the grid.
""" has_region

@doc """
    get_position(grid::GeoGrid, region::String) -> Union{Tuple{Int, Int}, Nothing}

Get the position of a region in the grid.
Returns `nothing` if the region doesn't exist.
""" get_position

@doc """
    get_region_at(grid::GeoGrid, row::Int, col::Int) -> Union{String, Nothing}

Get the region name at a specific grid position.
Returns `nothing` if no region exists at that position.
""" get_region_at

@doc """
    get_regions(grid::GeoGrid) -> Vector{String}

Get all region names in the grid.
""" get_regions

@doc """
    is_complete_rectangle(grid::GeoGrid) -> Bool

Check if the grid forms a complete rectangle (no missing cells).
""" is_complete_rectangle

@doc """
    has_neighbor_below(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region below it in the same column.
Returns `false` if the region doesn't exist in the grid.
""" has_neighbor_below

@doc """
    has_neighbor_left(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region to its left in the same row.
Returns `false` if the region doesn't exist in the grid.
""" has_neighbor_left

@doc """
    has_neighbor_right(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region to its right in the same row.
Returns `false` if the region doesn't exist in the grid.
""" has_neighbor_right

@doc """
    has_neighbor_above(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region above it in the same column.
Returns `false` if the region doesn't exist in the grid.
""" has_neighbor_above