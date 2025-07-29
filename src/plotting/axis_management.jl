"""
Axis management utilities for geofacet plotting functionality.
"""

using Makie

"""
    _get_yaxis_position(axis_kwargs)

Get the yaxis position from axis kwargs, defaulting to :left (Makie's default).
"""
function _get_yaxis_position(axis_kwargs::NamedTuple)
    return get(axis_kwargs, :yaxisposition, :left)
end

"""
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
"""
function _merge_axis_kwargs(common_kwargs, per_axis_kwargs_list, per_axis_decoration_kwargs, num_axes)
    # If no specific number of axes requested and no per-axis kwargs, default to 1
    if num_axes == 0 && isempty(per_axis_kwargs_list)
        num_axes = 1
    elseif num_axes == 0
        num_axes = length(per_axis_kwargs_list)
    end

    processed_kwargs = NamedTuple[]

    for i in 1:num_axes
        # Start with common kwargs
        merged = common_kwargs

        # Add per-axis kwargs if available
        if i <= length(per_axis_kwargs_list)
            merged = merge(merged, per_axis_kwargs_list[i])
        end

        # Add per-axis decoration kwargs (highest priority)
        if i <= length(per_axis_decoration_kwargs)
            merged = merge(merged, per_axis_decoration_kwargs[i])
        end

        push!(processed_kwargs, merged)
    end

    return processed_kwargs
end

function hide_all_decorations!(layout::GridLayout)
    # Find all Axis objects in the GridLayout
    for content in layout.content
        if content.content isa Axis
            hidedecorations!(content.content)
            hidespines!(content.content)
        end
    end
    return nothing
end

function collect_gl_axes(layouts::Vector{L}) where {L <: GridLayout}
    axes = Axis[]

    for layout in layouts
        _collect_axes_recursive!(axes, layout)
    end

    return axes
end

"""
    collect_gl_axes_by_position(layouts)

Collect axes from GridLayouts grouped by their position (creation order).
Returns a vector where each element contains all axes at that position across all facets.

# Arguments
- `layouts`: Vector of GridLayout objects from different facets

# Returns
Vector{Vector{Axis}} where result[i] contains all axes at position i across facets
"""
function collect_gl_axes_by_position(layouts::Vector{L}) where {L <: GridLayout}
    # Dictionary to store axes by their creation order within each layout
    axes_by_position = Dict{Int, Vector{Axis}}()

    for layout in layouts
        layout_axes = _collect_axes_ordered(layout)
        for (pos, axis) in enumerate(layout_axes)
            if !haskey(axes_by_position, pos)
                axes_by_position[pos] = Axis[]
            end
            push!(axes_by_position[pos], axis)
        end
    end

    # Convert to vector, ensuring consistent ordering
    if isempty(axes_by_position)
        return Vector{Axis}[]
    end

    max_position = maximum(keys(axes_by_position))
    return [get(axes_by_position, i, Axis[]) for i in 1:max_position]
end

"""
    _collect_axes_ordered(layout)

Collect axes from a GridLayout in the order they appear in the grid.
This ensures consistent ordering across facets.
"""
function _collect_axes_ordered(layout::GridLayout)
    axes = Axis[]
    _collect_axes_recursive_ordered!(axes, layout)
    return axes
end

"""
    _collect_axes_recursive!(axes, layout)

Recursively collect all Axis objects from a GridLayout, including nested GridLayouts.
"""
function _collect_axes_recursive!(axes::Vector{Axis}, layout::GridLayout)
    for content in layout.content
        if content.content isa Axis
            push!(axes, content.content)
        elseif content.content isa GridLayout
            # Recursively search nested GridLayouts
            _collect_axes_recursive!(axes, content.content)
        end
    end
    return nothing
end

"""
    _collect_axes_recursive_ordered!(axes, layout)

Recursively collect all Axis objects from a GridLayout in grid position order.
This ensures consistent ordering of axes across different facets.
"""
function _collect_axes_recursive_ordered!(axes::Vector{Axis}, layout::GridLayout)
    # Sort content by grid position to ensure consistent ordering
    sorted_content = sort(layout.content, by = c -> (c.span.rows.start, c.span.cols.start))

    for content in sorted_content
        if content.content isa Axis
            push!(axes, content.content)
        elseif content.content isa GridLayout
            # Recursively search nested GridLayouts
            _collect_axes_recursive_ordered!(axes, content.content)
        end
    end
    return nothing
end