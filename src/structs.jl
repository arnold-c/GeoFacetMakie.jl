"""
Data structures for GeoFacetMakie.jl
"""

using StructArrays

export GeoGrid, GridEntry

"""
    GridEntry

A single entry in a geographical grid, containing the region identifier
and its position coordinates.

# Fields
- `region::String`: Region identifier/code
- `row::Int`: Grid row position (≥ 1)
- `col::Int`: Grid column position (≥ 1)
"""
struct GridEntry
    region::String
    row::Int
    col::Int
end

"""
    GeoGrid

A geographical grid layout using StructArray for efficient storage.
Stores region names and their (row, col) positions in a structure-of-arrays format.

This provides better memory efficiency and performance through:
- Structure-of-Arrays (SOA) layout for better cache locality
- Vectorized operations on grid data
- Natural integration with DataFrames.jl ecosystem

# Examples
```julia
# Create from vectors
grid = StructArray{GridEntry}((
    region = ["CA", "NY", "TX", "FL"],
    row = [1, 1, 2, 2],
    col = [1, 2, 1, 2]
))

# Access individual fields
regions = grid.region
rows = grid.row
cols = grid.col

# Iterate over entries
for grid_entry in grid
    println("\$(grid_entry.region) at (\$(grid_entry.row), \$(grid_entry.col))")
end
```
"""
const GeoGrid = StructArray{GridEntry}

"""
    GeoGrid(name::String, positions::Dict{String, Tuple{Int, Int}})

Backward-compatible constructor for creating a GeoGrid from a name and positions dictionary.

# Arguments
- `name::String`: Name of the grid layout (for backward compatibility, not stored)
- `positions::Dict{String, Tuple{Int, Int}}`: Mapping from region names to (row, col) positions

# Validation
- Region names cannot be empty or whitespace-only
- Grid positions must be positive integers (≥ 1)
- No two regions can occupy the same position

# Examples
```julia
# Create a simple 2x2 grid (backward compatible)
grid = GeoGrid("test", Dict(
    "CA" => (1, 1), "NY" => (1, 2),
    "TX" => (2, 1), "FL" => (2, 2)
))
```
"""
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

    # Validate no duplicate positions
    position_to_region = Dict{Tuple{Int, Int}, String}()
    for (region, position) in positions
        if haskey(position_to_region, position)
            existing_region = position_to_region[position]
            throw(ArgumentError("Position conflict: regions '$existing_region' and '$region' both at position $position"))
        end
        position_to_region[position] = region
    end

    # Create StructArray from dictionary
    entries = [GridEntry(region, row, col) for (region, (row, col)) in positions]
    return StructArray(entries)
end

"""
    GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int})

Create a GeoGrid directly from separate vectors of regions, rows, and columns.

# Arguments
- `regions::Vector{String}`: Vector of region identifiers
- `rows::Vector{Int}`: Vector of row positions
- `cols::Vector{Int}`: Vector of column positions

# Examples
```julia
grid = GeoGrid(
    ["CA", "NY", "TX", "FL"],
    [1, 1, 2, 2],
    [1, 2, 1, 2]
)
```
"""
function GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int})
    if !(length(regions) == length(rows) == length(cols))
        throw(ArgumentError("All input vectors must have the same length"))
    end
    
    # Validate region names
    for region_name in regions
        if isempty(strip(region_name))
            throw(ArgumentError("Region names cannot be empty or whitespace-only"))
        end
    end

    # Validate positions are positive
    for (i, (region, row, col)) in enumerate(zip(regions, rows, cols))
        if row <= 0 || col <= 0
            throw(ArgumentError("Grid positions must be positive integers (≥ 1), got ($row, $col) for region '$region'"))
        end
    end

    return StructArray{GridEntry}((region = regions, row = rows, col = cols))
end
