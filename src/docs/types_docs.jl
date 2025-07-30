"""
Documentation for GeoFacetMakie.jl types
"""

@doc """
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

# Working with Names and Metadata
```julia
# Create entry with custom display name
entry = GridEntry("CA", 1, 2, "California")
println(entry.name)  # "California"

# Create entry with metadata (e.g., from CSV loading)
metadata = Dict("population" => 39538223, "area_km2" => 423970)
entry = GridEntry("CA", 1, 2, "California", metadata)

# Access metadata
pop = entry.metadata["population"]  # 39538223
area = entry.metadata["area_km2"]   # 423970

# Use in plotting functions (assuming you have access to the grid entry)
# Note: This is a conceptual example - in practice you'd need to look up
# the grid entry for the current region within your plot function
geofacet(data, :state, (gl, data; kwargs...) -> begin
    ax = Axis(gl[1, 1]; kwargs...)
    # Use region code for title (standard approach)
    ax.title = data.state[1]  # "CA"
    
    # Or if you have access to the grid entry with display names:
    # ax.title = entry.name  # "California" instead of "CA"
    
    lines!(ax, data.year, data.value)
end)

# Filter grids by metadata
large_states = filter(e -> get(e.metadata, "population", 0) > 10_000_000, grid)
```
""" GridEntry

@doc """
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
""" GeoGrid

@doc """
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
""" GeoGrid(name::String, positions::Dict{String, Tuple{Int, Int}})

@doc """
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
""" GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int})

@doc """
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
""" GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int}, names::Vector{String})

@doc """
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
""" GeoGrid(regions::Vector{String}, rows::Vector{Int}, cols::Vector{Int}, names::Vector{String}, metadata::Vector{Dict{String, Any}})

