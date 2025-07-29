"""
Data processing utilities for geofacet plotting functionality.
"""

using DataFrames
using Makie
function _prepare_grouped_data(data, region_col)
    return groupby(data, region_col)
end


function _get_available_regions(grouped_data, region_col)
    # Get unique region codes and convert to uppercase for case-insensitive matching
    return Set(uppercase(key[region_col]) for key in keys(grouped_data))
end


function _has_region_data(available_regions::Set{String}, region_code::String)
    return uppercase(region_code) in available_regions
end


function _get_region_data(grouped_data, region_col, region_code)
    # Try to find the group with case-insensitive matching
    for (key, group) in pairs(grouped_data)
        if uppercase(string(key[region_col])) == uppercase(region_code)
            return group
        end
    end
    return nothing
end


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

