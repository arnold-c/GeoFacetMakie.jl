"""
GridEntry type definition and methods for GeoFacetMakie.jl
"""

using StructArrays

export GridEntry
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