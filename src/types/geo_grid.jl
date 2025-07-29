"""
GeoGrid type definition and constructors for GeoFacetMakie.jl
"""

using StructArrays

export GeoGrid

const GeoGrid = StructArray{GridEntry}
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