"""
Data structures for GeoFacetMakie.jl
"""

using StructArrays

export GeoGrid, GridEntry

"""
    GridEntry

A single entry in a geographical grid, containing the region identifier,
its position coordinates, display name, and optional metadata.

# Fields
- `region::String`: Region identifier/code
- `row::Int`: Grid row position (≥ 1)
- `col::Int`: Grid column position (≥ 1)
- `name::String`: Display name for the region (defaults to region if not provided)
- `metadata::Dict{String,Any}`: Additional metadata from CSV columns

# Constructors
```julia
# Basic constructor (backward compatible)
entry = GridEntry("CA", 1, 2)

# With custom name
entry = GridEntry("CA", 1, 2, "California")

# With name and metadata
entry = GridEntry("CA", 1, 2, "California", Dict("population" => 39538223))
```

# Iteration and Indexing
GridEntry supports iteration, unpacking, and indexing for backward compatibility:
```julia
entry = GridEntry("CA", 1, 2)

# Unpack core fields (backward compatible)
region, row, col = entry

# Index access (backward compatible)
region = entry[1]  # "CA"
row = entry[2]     # 1
col = entry[3]     # 2

# Access new fields directly
name = entry.name        # "CA" (defaults to region)
metadata = entry.metadata # Dict{String,Any}()

# Iterate over core fields (backward compatible)
for value in entry
    println(value)  # Prints "CA", 1, 2
end

# Convert to array (backward compatible)
values = collect(entry)  # ["CA", 1, 2]

# Functional style
regions = map(e -> e[1], grid)  # Extract all regions
```
"""
struct GridEntry
    region::String
    row::Int
    col::Int
    name::String
    metadata::Dict{String,Any}

    # Backward compatible constructor (3 arguments)
    function GridEntry(region::String, row::Int, col::Int)
        # Validate region name
        if isempty(strip(region))
            throw(ArgumentError("Region names cannot be empty or whitespace-only"))
        end

        # Validate positions are positive
        if row <= 0 || col <= 0
            throw(ArgumentError("Grid positions must be positive integers (≥ 1), got ($row, $col) for region '$region'"))
        end

        return new(region, row, col, region, Dict{String,Any}())
    end

    # Constructor with custom name
    function GridEntry(region::String, row::Int, col::Int, name::String)
        # Validate region name
        if isempty(strip(region))
            throw(ArgumentError("Region names cannot be empty or whitespace-only"))
        end

        # Validate positions are positive
        if row <= 0 || col <= 0
            throw(ArgumentError("Grid positions must be positive integers (≥ 1), got ($row, $col) for region '$region'"))
        end

        # Use region as name if name is empty
        display_name = isempty(strip(name)) ? region : name

        return new(region, row, col, display_name, Dict{String,Any}())
    end

    # Full constructor with name and metadata
    function GridEntry(region::String, row::Int, col::Int, name::String, metadata::Dict{String,Any})
        # Validate region name
        if isempty(strip(region))
            throw(ArgumentError("Region names cannot be empty or whitespace-only"))
        end

        # Validate positions are positive
        if row <= 0 || col <= 0
            throw(ArgumentError("Grid positions must be positive integers (≥ 1), got ($row, $col) for region '$region'"))
        end

        # Use region as name if name is empty
        display_name = isempty(strip(name)) ? region : name

        return new(region, row, col, display_name, metadata)
    end
end

# Make GridEntry iterable to support unpacking: region, row, col = entry
# Note: Iteration maintains backward compatibility by only returning core fields
Base.iterate(entry::GridEntry) = (entry.region, 2)
function Base.iterate(entry::GridEntry, state::Int)
    return state == 2 ? (entry.row, 3) :
        state == 3 ? (entry.col, 4) :
        nothing
end
Base.length(::GridEntry) = 3

# Add indexing support: entry[1] = region, entry[2] = row, entry[3] = col
# Note: Indexing maintains backward compatibility by only accessing core fields
function Base.getindex(entry::GridEntry, i::Int)
    return i == 1 ? entry.region :
        i == 2 ? entry.row :
        i == 3 ? entry.col :
        throw(BoundsError(entry, i))
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
