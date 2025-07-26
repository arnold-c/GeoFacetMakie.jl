"""
Grid loading functionality for GeoFacetMakie.

This module provides functions to load geographical grid layouts from CSV files,
particularly those from the geofacet R package ecosystem.
"""

using CSV
using DataFrames

"""
    load_grid_from_csv(csv_path::String) -> GeoGrid

Load a geographical grid from a CSV file in geofacet format.

The CSV file should have columns: row, col, code, name
- row: Grid row position (integer)
- col: Grid column position (integer) 
- code: Region identifier/abbreviation (string)
- name: Full region name (string)

# Arguments
- `csv_path::String`: Path to the CSV file

# Returns
- `GeoGrid`: A GeoGrid object containing the loaded grid data

# Example
```julia
grid = load_grid_from_csv("path/to/us_state_grid1.csv")
```
"""
function load_grid_from_csv(csv_path::String)
    if !isfile(csv_path)
        throw(ArgumentError("Grid file not found: $csv_path"))
    end
    
    try
        df = CSV.read(csv_path, DataFrame)
        
        # Validate required columns
        required_cols = ["row", "col", "code", "name"]
        missing_cols = setdiff(required_cols, names(df))
        if !isempty(missing_cols)
            throw(ArgumentError("Missing required columns: $(join(missing_cols, ", "))"))
        end
        
        # Create positions dictionary: code -> (row, col)
        positions = Dict{String, Tuple{Int, Int}}()
        
        for row in eachrow(df)
            code = string(row.code)
            positions[code] = (row.row, row.col)
        end
        
        # Extract grid name from filename
        grid_name = splitext(basename(csv_path))[1]
        
        return GeoGrid(grid_name, positions)
        
    catch e
        if isa(e, ArgumentError)
            rethrow(e)
        else
            throw(ArgumentError("Failed to parse CSV file: $csv_path. Error: $e"))
        end
    end
end

"""
    load_us_state_grid(version::Int = 1) -> GeoGrid

Load a predefined US state grid layout.

# Arguments
- `version::Int`: Grid version number (1, 2, or 3). Default is 1.

# Returns
- `GeoGrid`: US state grid layout

# Example
```julia
# Load the standard US state grid (includes DC)
grid = load_us_state_grid(1)

# Load alternative layout
grid2 = load_us_state_grid(2)
```
"""
function load_us_state_grid(version::Int = 1)
    if version ∉ [1, 2, 3]
        throw(ArgumentError("US state grid version must be 1, 2, or 3"))
    end
    
    grid_file = joinpath(@__DIR__, "data", "grids", "us_state_grid$(version).csv")
    return load_grid_from_csv(grid_file)
end

"""
    load_us_state_grid_without_dc(version::Int = 1) -> GeoGrid

Load a US state grid layout excluding Washington DC.

# Arguments
- `version::Int`: Grid version number (1, 2, or 3). Default is 1.

# Returns
- `GeoGrid`: US state grid layout without DC

# Example
```julia
grid = load_us_state_grid_without_dc(1)
```
"""
function load_us_state_grid_without_dc(version::Int = 1)
    if version ∉ [1, 2, 3]
        throw(ArgumentError("US state grid version must be 1, 2, or 3"))
    end
    
    grid_file = joinpath(@__DIR__, "data", "grids", "us_state_without_DC_grid$(version).csv")
    return load_grid_from_csv(grid_file)
end

"""
    load_us_contiguous_grid() -> GeoGrid

Load a US contiguous states grid layout (48 contiguous states + DC).

# Returns
- `GeoGrid`: US contiguous states grid layout

# Example
```julia
grid = load_us_contiguous_grid()
```
"""
function load_us_contiguous_grid()
    grid_file = joinpath(@__DIR__, "data", "grids", "us_state_contiguous_grid1.csv")
    return load_grid_from_csv(grid_file)
end

"""
    list_available_grids() -> Vector{String}

List all available predefined grid layouts.

# Returns
- `Vector{String}`: Names of available grid files

# Example
```julia
grids = list_available_grids()
println("Available grids: ", join(grids, ", "))
```
"""
function list_available_grids()
    grids_dir = joinpath(@__DIR__, "data", "grids")
    if !isdir(grids_dir)
        return String[]
    end
    
    csv_files = filter(f -> endswith(f, ".csv"), readdir(grids_dir))
    return [splitext(f)[1] for f in csv_files]
end

"""
    load_grid(grid_name::String) -> GeoGrid

Load a grid by name from the available predefined grids.

# Arguments
- `grid_name::String`: Name of the grid (without .csv extension)

# Returns
- `GeoGrid`: The requested grid layout

# Example
```julia
grid = load_grid("us_state_grid1")
grid = load_grid("us_state_without_DC_grid2")
```
"""
function load_grid(grid_name::String)
    grid_file = joinpath(@__DIR__, "data", "grids", "$(grid_name).csv")
    return load_grid_from_csv(grid_file)
end

# Export functions
export load_grid_from_csv, load_us_state_grid, load_us_state_grid_without_dc, 
       load_us_contiguous_grid, list_available_grids, load_grid