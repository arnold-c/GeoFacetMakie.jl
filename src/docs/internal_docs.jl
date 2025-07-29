"""
Documentation for GeoFacetMakie.jl internal functions
These functions are not exported and are used internally by the package.
"""

# Data processing functions
@doc """
    _prepare_grouped_data(data, region_col)

Group data by region column using DataFrames GroupedDataFrame directly.
No data copying - preserves original data structure.
""" _prepare_grouped_data

@doc """
    _get_available_regions(grouped_data, region_col)

Extract available region codes from GroupedDataFrame for case-insensitive lookup.
Returns a Set of uppercase region codes for efficient membership testing.
""" _get_available_regions

@doc """
    _has_region_data(available_regions, region_code)

Check if region data exists, handling case-insensitive matching.
Returns boolean instead of data for efficiency.
""" _has_region_data

@doc """
    _get_region_data(grouped_data, region_col, region_code)

Get data for a specific region from GroupedDataFrame, handling case-insensitive matching.
""" _get_region_data

@doc """
    _has_labeled_plots(fig)

Check if any axes in the figure contain plots with labels that can be used in a legend.
Returns true if at least one labeled plot is found, false otherwise.
""" _has_labeled_plots

# Axis management functions
@doc """
    _get_yaxis_position(axis_kwargs)

Get the yaxis position from axis kwargs, defaulting to :left (Makie's default).
""" _get_yaxis_position

@doc """
    _merge_axis_kwargs(common_kwargs, per_axis_kwargs_list, per_axis_decoration_kwargs, num_axes)

Merge common axis kwargs, per-axis kwargs, and per-axis decoration hiding kwargs.
Returns a vector of merged NamedTuples for each axis.

# Arguments
- `common_kwargs`: NamedTuple applied to all axes
- `per_axis_kwargs_list`: Vector of NamedTuples for per-axis kwargs
- `per_axis_decoration_kwargs`: Vector of NamedTuples with per-axis decoration hiding settings
- `num_axes`: Number of axes (used when per_axis_kwargs_list is shorter)

# Merging Priority (highest to lowest)
1. Per-axis decoration hiding kwargs
2. Per-axis kwargs from axis_kwargs_list[i]
3. Common kwargs from common_axis_kwargs
""" _merge_axis_kwargs

@doc """
    collect_gl_axes_by_position(layouts)

Collect axes from GridLayouts grouped by their position (creation order).
Returns a vector where each element contains all axes at that position across all facets.

# Arguments
- `layouts`: Vector of GridLayout objects from different facets

# Returns
Vector{Vector{Axis}} where result[i] contains all axes at position i across facets
""" collect_gl_axes_by_position

@doc """
    _collect_axes_ordered(layout)

Collect axes from a GridLayout in the order they appear in the grid.
This ensures consistent ordering across facets.
""" _collect_axes_ordered

@doc """
    _collect_axes_recursive!(axes, layout)

Recursively collect all Axis objects from a GridLayout, including nested GridLayouts.
""" _collect_axes_recursive!

@doc """
    _collect_axes_recursive_ordered!(axes, layout)

Recursively collect all Axis objects from a GridLayout in grid position order.
This ensures consistent ordering of axes across different facets.
""" _collect_axes_recursive_ordered!

