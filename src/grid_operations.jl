"""
Grid operations and utility functions for GeoFacetMakie.jl
"""

export grid_dimensions, validate_grid, has_region, get_position, get_region_at, get_regions, is_complete_rectangle, has_neighbor_below, has_neighbor_left, has_neighbor_right, has_neighbor_above

"""
    grid_dimensions(grid::GeoGrid) -> Tuple{Int, Int}

Get the dimensions of a grid as (max_row, max_col).
Returns (0, 0) for empty grids.
"""
function grid_dimensions(grid::GeoGrid)
    if isempty(grid)
        return (0, 0)
    end

    max_row = maximum(grid.row)
    max_col = maximum(grid.col)
    return (max_row, max_col)
end

"""
    validate_grid(grid::GeoGrid) -> Bool

Validate that no two regions occupy the same position.
Returns `true` if valid, throws `ArgumentError` if conflicts exist.
"""
function validate_grid(grid::GeoGrid)
    position_to_region = Dict{Tuple{Int, Int}, String}()

    for entry in grid
        position = (entry.row, entry.col)
        if haskey(position_to_region, position)
            existing_region = position_to_region[position]
            throw(ArgumentError("Position conflict: regions '$existing_region' and '$(entry.region)' both at position $position"))
        end
        position_to_region[position] = entry.region
    end

    return true
end

"""
    has_region(grid::GeoGrid, region::String) -> Bool

Check if a region exists in the grid.
"""
function has_region(grid::GeoGrid, region::String)
    return region in grid.region
end

"""
    get_position(grid::GeoGrid, region::String) -> Union{Tuple{Int, Int}, Nothing}

Get the position of a region in the grid.
Returns `nothing` if the region doesn't exist.
"""
function get_position(grid::GeoGrid, region::String)
    idx = findfirst(==(region), grid.region)
    return isnothing(idx) ? nothing : (grid.row[idx], grid.col[idx])
end

"""
    get_region_at(grid::GeoGrid, row::Int, col::Int) -> Union{String, Nothing}

Get the region name at a specific grid position.
Returns `nothing` if no region exists at that position.
"""
function get_region_at(grid::GeoGrid, row::Int, col::Int)
    idx = findfirst(i -> grid.row[i] == row && grid.col[i] == col, eachindex(grid))
    return isnothing(idx) ? nothing : grid.region[idx]
end

"""
    get_regions(grid::GeoGrid) -> Vector{String}

Get all region names in the grid.
"""
function get_regions(grid::GeoGrid)
    return grid.region
end

"""
    is_complete_rectangle(grid::GeoGrid) -> Bool

Check if the grid forms a complete rectangle (no missing cells).
"""
function is_complete_rectangle(grid::GeoGrid)
    if isempty(grid)
        return true  # Empty grid is technically complete
    end

    max_row, max_col = grid_dimensions(grid)
    expected_cells = max_row * max_col
    actual_cells = length(grid)

    return expected_cells == actual_cells
end

"""
    has_neighbor_below(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region below it in the same column.
Returns `false` if the region doesn't exist in the grid.
"""
function has_neighbor_below(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.col .== col) .& (grid.row .> row))
end

"""
    has_neighbor_left(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region to its left in the same row.
Returns `false` if the region doesn't exist in the grid.
"""
function has_neighbor_left(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.row .== row) .& (grid.col .< col))
end

"""
    has_neighbor_right(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region to its right in the same row.
Returns `false` if the region doesn't exist in the grid.
"""
function has_neighbor_right(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.row .== row) .& (grid.col .> col))
end

"""
    has_neighbor_above(grid::GeoGrid, region::String) -> Bool

Check if a region has any neighboring region above it in the same column.
Returns `false` if the region doesn't exist in the grid.
"""
function has_neighbor_above(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.col .== col) .& (grid.row .< row))
end
