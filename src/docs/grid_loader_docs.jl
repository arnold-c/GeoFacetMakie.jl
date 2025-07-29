"""
Documentation for GeoFacetMakie.jl grid loading functionality
"""

@doc """
    load_grid_from_csv(filename::String, directory::String) -> GeoGrid

Load a geographical grid from a CSV file in geofacet format.

The CSV file should have columns: row, col, code, and optionally name
- row: Grid row position (integer)
- col: Grid column position (integer)
- code: Region identifier/abbreviation (string)
- name: Full region name (string, optional - defaults to code if missing)
- Additional columns will be stored as metadata

# Arguments
- `filename::String`: Name of the CSV file (with or without .csv extension)
- `directory::String`: Directory containing the CSV file

# Returns
- `GeoGrid`: A GeoGrid object containing the loaded grid data

# Example
```julia
# Load from custom directory
grid = load_grid_from_csv("us_state_grid1.csv", "/path/to/grids")

# Load from package data directory
grids_dir = joinpath(pkgdir(GeoFacetMakie), "src", "data", "grids")
grid = load_grid_from_csv("us_state_grid1", grids_dir)
```
""" load_grid_from_csv(filename::String, directory::String)

@doc """
    load_grid_from_csv(filename::String) -> GeoGrid

Load a geographical grid from the package's default grids directory.

# Arguments
- `filename::String`: Name of the CSV file (with or without .csv extension)

# Returns
- `GeoGrid`: A GeoGrid object containing the loaded grid data

# Example
```julia
# Load from package default directory
grid = load_grid_from_csv("us_state_grid1")
grid = load_grid_from_csv("eu_grid1.csv")
```
""" load_grid_from_csv(filename::String)

@doc """
    list_available_grids() -> Vector{String}

List all available predefined grid layouts.

# Returns
- `Vector{String}`: Names of available grid files

# Example
```julia
grids = list_available_grids()
println("Available grids: ", join(grids, ", "))
```
""" list_available_grids

