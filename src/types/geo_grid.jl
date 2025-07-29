"""
GeoGrid type definition and constructors for GeoFacetMakie.jl
"""

using StructArrays

export GeoGrid

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
# Create from vectors (backward compatible)
grid = StructArray{GridEntry}((
    region = ["CA", "NY", "TX", "FL"],
    row = [1, 1, 2, 2],
    col = [1, 2, 1, 2],
    name = ["California", "New York", "Texas", "Florida"],
    metadata = [Dict{String,Any}(), Dict{String,Any}(), Dict{String,Any}(), Dict{String,Any}()]
))

# Access individual fields
regions = grid.region
rows = grid.row
cols = grid.col
names = grid.name
metadata = grid.metadata

# Iterate over entries
for grid_entry in grid
    println("\$(grid_entry.region) (\$(grid_entry.name)) at (\$(grid_entry.row), \$(grid_entry.col))")
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
Names will default to regions and metadata will be empty.

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

    # Create with names defaulting to regions and empty metadata
    names = copy(regions)
    metadata = [Dict{String,Any}() for _ in regions]

    return StructArray{GridEntry}((
        region = regions, 
        row = rows, 
        col = cols, 
        name = names, 
        metadata = metadata
    ))
end

"""
    GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int}, names::Vector{String})

Create a GeoGrid directly from separate vectors of regions, rows, columns, and names.
Metadata will be empty.

# Arguments
- `regions::Vector{String}`: Vector of region identifiers
- `rows::Vector{Int}`: Vector of row positions
- `cols::Vector{Int}`: Vector of column positions
- `names::Vector{String}`: Vector of display names

# Examples
```julia
grid = GeoGrid(
    ["CA", "NY", "TX", "FL"],
    [1, 1, 2, 2],
    [1, 2, 1, 2],
    ["California", "New York", "Texas", "Florida"]
)
```
"""
function GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int}, names::Vector{String})
    if !(length(regions) == length(rows) == length(cols) == length(names))
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

    # Default empty names to regions
    display_names = [isempty(strip(name)) ? region : name for (region, name) in zip(regions, names)]
    metadata = [Dict{String,Any}() for _ in regions]

    return StructArray{GridEntry}((
        region = regions, 
        row = rows, 
        col = cols, 
        name = display_names, 
        metadata = metadata
    ))
end

"""
    GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int}, names::Vector{String}, metadata::Vector{Dict{String,Any}})

Create a GeoGrid directly from separate vectors of regions, rows, columns, names, and metadata.

# Arguments
- `regions::Vector{String}`: Vector of region identifiers
- `rows::Vector{Int}`: Vector of row positions
- `cols::Vector{Int}`: Vector of column positions
- `names::Vector{String}`: Vector of display names
- `metadata::Vector{Dict{String,Any}}`: Vector of metadata dictionaries

# Examples
```julia
grid = GeoGrid(
    ["CA", "NY", "TX", "FL"],
    [1, 1, 2, 2],
    [1, 2, 1, 2],
    ["California", "New York", "Texas", "Florida"],
    [Dict("pop" => 39538223), Dict("pop" => 20201249), Dict("pop" => 29145505), Dict("pop" => 21538187)]
)
```
"""
function GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int}, names::Vector{String}, metadata::Vector{Dict{String,Any}})
    if !(length(regions) == length(rows) == length(cols) == length(names) == length(metadata))
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

    # Default empty names to regions
    display_names = [isempty(strip(name)) ? region : name for (region, name) in zip(regions, names)]

    return StructArray{GridEntry}((
        region = regions, 
        row = rows, 
        col = cols, 
        name = display_names, 
        metadata = metadata
    ))
end