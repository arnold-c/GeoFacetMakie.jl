"""
Predefined grid constants for GeoFacetMakie.jl

This file dynamically creates constants for all available grid layouts,
making them easily accessible without needing to call load_grid_from_csv() each time.

All grids are loaded from the geofacet grid collection and cached as constants
for optimal performance using a generator pattern.
"""

# Get all available grids at compile time
const AVAILABLE_GRIDS = list_available_grids()

# Programmatically export all grid constants
for grid_name in AVAILABLE_GRIDS
    @eval export $(Symbol(grid_name))
end

# Programmatically create all grid constants using a generator pattern
for grid_name in AVAILABLE_GRIDS
    grid_symbol = Symbol(grid_name)

    # Create docstring
    grid_display_name = replace(grid_name, "_" => " ")
    docstring = """
        $grid_name

    Predefined $grid_display_name layout.

    This grid is automatically loaded from the geofacet grid collection.
    If loading fails, it falls back to an empty grid with a warning.
    """

    # Create the constant with error handling
    @eval begin
        @doc $docstring
        const $grid_symbol = let
            try
                load_grid_from_csv($grid_name)
            catch e
                @warn "Could not load $($grid_name): $e"
                # Fallback to empty grid if loading fails
                GeoGrid($(grid_name * "_fallback"), Dict{String, Tuple{Int, Int}}())
            end
        end
    end
end

# Export count for verification
const PREDEFINED_GRIDS_COUNT = length(AVAILABLE_GRIDS)

"""
    get_predefined_grids_count() -> Int

Get the number of predefined grid constants that were created.

# Returns
- `Int`: Number of predefined grid constants available

# Example
```julia
count = get_predefined_grids_count()
println("Available predefined grids: ", count)
```
"""
get_predefined_grids_count() = PREDEFINED_GRIDS_COUNT

export get_predefined_grids_count

