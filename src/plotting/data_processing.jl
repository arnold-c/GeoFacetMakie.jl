"""
Data processing utilities for geofacet plotting functionality.
"""

using DataFrames
using Makie

"""
    _prepare_grouped_data(data, region_col) -> GroupedDataFrame

Group the input data by the specified region column for efficient processing.
This creates a GroupedDataFrame that allows fast lookup of data subsets by region.

# Arguments
- `data`: Input DataFrame or similar tabular data structure
- `region_col`: Symbol or string specifying the column containing region identifiers

# Returns
- `GroupedDataFrame`: Grouped data structure for efficient region-based access
"""
function _prepare_grouped_data(data, region_col)
    return groupby(data, region_col)
end

"""
    _get_available_regions(grouped_data, region_col) -> Set{String}

Extract all available region codes from grouped data, converting to uppercase
for case-insensitive matching.

# Arguments
- `grouped_data`: GroupedDataFrame from `_prepare_grouped_data`
- `region_col`: Symbol specifying the region column name

# Returns
- `Set{String}`: Set of uppercase region codes available in the data
"""
function _get_available_regions(grouped_data, region_col)
    # Get unique region codes and convert to uppercase for case-insensitive matching
    return Set(uppercase(key[region_col]) for key in keys(grouped_data))
end

"""
    _has_region_data(available_regions::Set{String}, region_code::String) -> Bool

Check if a region code exists in the available regions set using case-insensitive matching.

# Arguments
- `available_regions`: Set of uppercase region codes from `_get_available_regions`
- `region_code`: Region code to check for

# Returns
- `Bool`: `true` if the region exists in the data, `false` otherwise
"""
function _has_region_data(available_regions::Set{String}, region_code::String)
    return uppercase(region_code) in available_regions
end

"""
    _get_region_data(grouped_data, region_col, region_code) -> Union{DataFrame, Nothing}

Retrieve the data subset for a specific region using case-insensitive matching.

# Arguments
- `grouped_data`: GroupedDataFrame from `_prepare_grouped_data`
- `region_col`: Symbol specifying the region column name
- `region_code`: Region code to retrieve data for

# Returns
- `DataFrame`: Data subset for the specified region, or `nothing` if not found
"""
function _get_region_data(grouped_data, region_col, region_code)
    # Try to find the group with case-insensitive matching
    for (key, group) in pairs(grouped_data)
        if uppercase(string(key[region_col])) == uppercase(region_code)
            return group
        end
    end
    return nothing
end

"""
    _has_labeled_plots(fig::Figure) -> Bool

Check if any plots in the figure have labels (for legend creation).
Recursively searches through all axes in the figure to find plots with non-empty labels.

# Arguments
- `fig`: Makie Figure object to search

# Returns
- `Bool`: `true` if any labeled plots are found, `false` otherwise
"""
function _has_labeled_plots(fig::Figure)
    for content in fig.content
        if content isa Axis
            # Check if this axis has any plots with labels
            for plot in content.scene.plots
                # Check if the plot has a non-empty label
                if haskey(plot.attributes, :label) && !isnothing(plot.label[]) && plot.label[] != ""
                    return true
                end
            end
        end
    end
    return false
end

