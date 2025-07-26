"""
Data structures for GeoFacetMakie.jl
"""

export GeoGrid

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