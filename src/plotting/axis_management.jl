"""
Axis management utilities for geofacet plotting functionality.
"""

using Makie

"""
    _get_yaxis_position(axis_kwargs::NamedTuple) -> Symbol

Extract the y-axis position from axis keyword arguments, defaulting to `:left`.

# Arguments
- `axis_kwargs`: NamedTuple containing axis configuration options

# Returns
- `Symbol`: Y-axis position (`:left` or `:right`)
"""
function _get_yaxis_position(axis_kwargs::NamedTuple)
    return get(axis_kwargs, :yaxisposition, :left)
end

"""
    _merge_axis_kwargs(common_kwargs, per_axis_kwargs_list, per_axis_decoration_kwargs, num_axes) -> Vector{NamedTuple}

Merge common axis kwargs, per-axis kwargs, and decoration kwargs in priority order.
Creates a vector of merged NamedTuples, one for each axis to be created.

# Arguments
- `common_kwargs`: NamedTuple applied to all axes (lowest priority)
- `per_axis_kwargs_list`: Vector of NamedTuples for specific axes (medium priority)
- `per_axis_decoration_kwargs`: Vector of NamedTuples for decoration hiding (highest priority)
- `num_axes`: Number of axes to create kwargs for

# Returns
- `Vector{NamedTuple}`: Merged kwargs for each axis, with decoration kwargs taking precedence

# Priority Order (highest to lowest)
1. `per_axis_decoration_kwargs` - Controls hiding of axis decorations
2. `per_axis_kwargs_list` - Axis-specific customizations
3. `common_kwargs` - Common settings applied to all axes
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

"""
    hide_all_decorations!(layout::GridLayout) -> Nothing

Hide all decorations and spines for all Axis objects within a GridLayout.
This is a utility function for completely cleaning up axis appearance.

# Arguments
- `layout`: GridLayout containing axes to modify

# Side Effects
- Calls `hidedecorations!` and `hidespines!` on all contained axes
"""
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

"""
    collect_gl_axes(layouts::Vector{GridLayout}) -> Vector{Axis}

Collect all Axis objects from a vector of GridLayouts, including nested layouts.
Used for applying operations (like axis linking) across multiple facets.

# Arguments
- `layouts`: Vector of GridLayout objects to search

# Returns
- `Vector{Axis}`: All axes found in the layouts, in discovery order
"""
function collect_gl_axes(layouts::Vector{L}) where {L <: GridLayout}
    axes = Axis[]

    for layout in layouts
        _collect_axes_recursive!(axes, layout)
    end

    return axes
end

"""
    collect_gl_axes_by_position(layouts::Vector{GridLayout}) -> Vector{Vector{Axis}}

Collect axes from multiple GridLayouts, grouped by their position within each layout.
This enables linking axes that occupy the same position across different facets.

# Arguments
- `layouts`: Vector of GridLayout objects to search

# Returns
- `Vector{Vector{Axis}}`: Axes grouped by position - `result[i]` contains all axes
  at position `i` across all layouts

# Example
If each layout has 2 axes, `result[1]` contains all first axes, `result[2]` contains all second axes.
This is essential for proper axis linking in multi-axis plots.
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
    _collect_axes_ordered(layout::GridLayout) -> Vector{Axis}

Collect all axes from a GridLayout in a consistent order based on grid position.

# Arguments
- `layout`: GridLayout to search

# Returns
- `Vector{Axis}`: Axes sorted by their grid position (row, then column)
"""
function _collect_axes_ordered(layout::GridLayout)
    axes = Axis[]
    _collect_axes_recursive_ordered!(axes, layout)
    return axes
end

"""
    _collect_axes_recursive!(axes::Vector{Axis}, layout::GridLayout) -> Nothing

Recursively collect all Axis objects from a GridLayout and its nested layouts.
Modifies the input `axes` vector in-place.

# Arguments
- `axes`: Vector to append found axes to
- `layout`: GridLayout to search recursively
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
    _collect_axes_recursive_ordered!(axes::Vector{Axis}, layout::GridLayout) -> Nothing

Recursively collect all Axis objects from a GridLayout in consistent order.
Sorts content by grid position before processing to ensure deterministic ordering.

# Arguments
- `axes`: Vector to append found axes to
- `layout`: GridLayout to search recursively

# Implementation Note
Sorting by `(row.start, col.start)` ensures axes are collected in a predictable order
regardless of creation sequence, which is crucial for multi-axis linking.
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