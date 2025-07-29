"""
Grid loading functionality for GeoFacetMakie.

This module provides functions to load geographical grid layouts from CSV files,
particularly those from the geofacet R package ecosystem.
"""

# Export functions
export load_grid_from_csv, list_available_grids, load_grid

using CSV
using DataFrames

"""
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
"""
function load_grid_from_csv(filename::String, directory::String)
    # Add .csv extension if not present
    csv_filename = endswith(filename, ".csv") ? filename : "$filename.csv"
    csv_path = joinpath(directory, csv_filename)

    if !isfile(csv_path)
        throw(ArgumentError("Grid file not found: $csv_path"))
    end

    try
        df = CSV.read(csv_path, DataFrame)

        # Validate required columns
        required_cols = ["row", "col"]
        missing_cols = setdiff(required_cols, names(df))
        if !isempty(missing_cols)
            throw(ArgumentError("Missing required columns: $(join(missing_cols, ", "))"))
        end

        # Find the code column (try different common names)
        code_col = nothing
        for col_name in ["code", "code_alpha3", "code_country", "code_iso_3166_2"]
            if col_name in names(df)
                code_col = col_name
                break
            end
        end

        if code_col === nothing
            throw(ArgumentError("Missing code column. Expected one of: code, code_alpha3, code_country, code_iso_3166_2"))
        end

        # Extract core data
        regions = string.(df[!, code_col])
        rows = df.row
        cols = df.col

        # Extract names (default to code if not present)
        display_names = if "name" in names(df)
            string.(df.name)
        else
            copy(regions)  # Default to region codes
        end

        # Extract metadata from additional columns
        core_columns = ["row", "col", "code", "name"]
        metadata_columns = setdiff(names(df), core_columns)

        metadata = if isempty(metadata_columns)
            # No additional columns, create empty metadata
            [Dict{String, Any}() for _ in regions]
        else
            # Create metadata dictionaries from additional columns
            [
                Dict{String, Any}(col => df[i, col] for col in metadata_columns)
                    for i in 1:nrow(df)
            ]
        end

        # Create StructArray with all fields
        return StructArray{GridEntry}(
            (
                region = regions,
                row = rows,
                col = cols,
                name = display_names,
                metadata = metadata,
            )
        )

    catch e
        if isa(e, ArgumentError)
            rethrow(e)
        else
            throw(ArgumentError("Failed to parse CSV file: $csv_path. Error: $e"))
        end
    end
end

"""
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
"""
function load_grid_from_csv(filename::String)
    grids_dir = joinpath(@__DIR__, "..", "data", "grids")
    return load_grid_from_csv(filename, grids_dir)
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
    grids_dir = joinpath(@__DIR__, "..", "data", "grids")
    if !isdir(grids_dir)
        return String[]
    end

    csv_files = filter(f -> endswith(f, ".csv"), readdir(grids_dir))
    return [splitext(f)[1] for f in csv_files]
end
