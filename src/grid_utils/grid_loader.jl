"""
Grid loading functionality for GeoFacetMakie.

This module provides functions to load geographical grid layouts from CSV files,
particularly those from the geofacet R package ecosystem.
"""

# Export functions
export load_grid_from_csv, list_available_grids

using CSV
using DataFrames
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

        # Find the code column using regex pattern matching
        code_col = nothing
        column_names = names(df)
        code_pattern = r"code"i  # Case-insensitive regex pattern

        # Find first column name containing "code" (case-insensitive)
        for col_name in column_names
            if occursin(code_pattern, col_name)
                code_col = col_name
                break
            end
        end

        if code_col === nothing
            throw(ArgumentError("Missing code column. No column name contains 'code' (case-insensitive)"))
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


function load_grid_from_csv(filename::String)
    grids_dir = joinpath(@__DIR__, "..", "data", "grids")
    return load_grid_from_csv(filename, grids_dir)
end


function list_available_grids()
    grids_dir = joinpath(@__DIR__, "..", "data", "grids")
    if !isdir(grids_dir)
        return String[]
    end

    csv_files = filter(f -> endswith(f, ".csv"), readdir(grids_dir))
    return [splitext(f)[1] for f in csv_files]
end
