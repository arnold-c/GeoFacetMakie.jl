"""
Data processing utilities for geofacet plotting functionality.
"""

using DataFrames
using Makie

"""
    _prepare_grouped_data(data, region_col)

Group data by region column using DataFrames GroupedDataFrame directly.
No data copying - preserves original data structure.
"""
function _prepare_grouped_data(data, region_col)
    return groupby(data, region_col)
end

"""
    _get_available_regions(grouped_data, region_col)

Extract available region codes from GroupedDataFrame for case-insensitive lookup.
Returns a Set of uppercase region codes for efficient membership testing.
"""
function _get_available_regions(grouped_data, region_col)
    # Get unique region codes and convert to uppercase for case-insensitive matching
    return Set(uppercase(key[region_col]) for key in keys(grouped_data))
end

"""
    _has_region_data(available_regions, region_code)

Check if region data exists, handling case-insensitive matching.
Returns boolean instead of data for efficiency.
"""
function _has_region_data(available_regions::Set{String}, region_code::String)
    return uppercase(region_code) in available_regions
end

"""
    _get_region_data(grouped_data, region_col, region_code)

Get data for a specific region from GroupedDataFrame, handling case-insensitive matching.
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
    _has_labeled_plots(fig)

Check if any axes in the figure contain plots with labels that can be used in a legend.
Returns true if at least one labeled plot is found, false otherwise.
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

