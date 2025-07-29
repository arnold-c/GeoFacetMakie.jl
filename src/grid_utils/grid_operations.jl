"""
Grid operations and utility functions for GeoFacetMakie.jl
"""

export grid_dimensions, validate_grid, has_region, get_position, get_region_at, get_regions, is_complete_rectangle, has_neighbor_below, has_neighbor_left, has_neighbor_right, has_neighbor_above
function grid_dimensions(grid::GeoGrid)
    if isempty(grid)
        return (0, 0)
    end

    max_row = maximum(grid.row)
    max_col = maximum(grid.col)
    return (max_row, max_col)
end


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


function has_region(grid::GeoGrid, region::String)
    return region in grid.region
end


function get_position(grid::GeoGrid, region::String)
    idx = findfirst(==(region), grid.region)
    return isnothing(idx) ? nothing : (grid.row[idx], grid.col[idx])
end


function get_region_at(grid::GeoGrid, row::Int, col::Int)
    idx = findfirst(i -> grid.row[i] == row && grid.col[i] == col, eachindex(grid))
    return isnothing(idx) ? nothing : grid.region[idx]
end


function get_regions(grid::GeoGrid)
    return grid.region
end


function is_complete_rectangle(grid::GeoGrid)
    if isempty(grid)
        return true  # Empty grid is technically complete
    end

    max_row, max_col = grid_dimensions(grid)
    expected_cells = max_row * max_col
    actual_cells = length(grid)

    return expected_cells == actual_cells
end


function has_neighbor_below(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.col .== col) .& (grid.row .> row))
end


function has_neighbor_left(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.row .== row) .& (grid.col .< col))
end


function has_neighbor_right(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.row .== row) .& (grid.col .> col))
end


function has_neighbor_above(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos

    # Use vectorized operations for efficiency
    return any((grid.col .== col) .& (grid.row .< row))
end
