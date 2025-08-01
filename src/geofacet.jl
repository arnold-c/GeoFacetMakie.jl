"""
Main geofacet plotting functionality for GeoFacetMakie.jl
"""

export geofacet, us_state_grid

"""
    us_state_grid

Predefined US state grid layout (includes Washington DC).

This is the standard US state grid layout from the geofacet R package,
providing a geographical arrangement of all 50 US states plus DC.

# Example
```julia
using GeoFacetMakie

# Use the predefined US state grid
geofacet(data, :state, plot_function; grid = us_state_grid)
```
"""
const us_state_grid = let
    try
        load_us_state_grid(1)
    catch e
        @warn "Could not load us_state_grid: $e"
        # Fallback to empty grid if loading fails
        GeoGrid(Dict{String, Tuple{Int, Int}}(), Dict{String, String}(), "us_state_grid1_fallback")
    end
end

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

"""
    geofacet(data, region_col, plot_func;
             grid = us_state_grid,
             figure_kwargs = NamedTuple(),
             common_axis_kwargs = NamedTuple(),
             axis_kwargs_list = NamedTuple[],
             link_axes = :none,
             missing_regions = :skip,
             hide_inner_decorations = true,
             kwargs...)

Create a geographically faceted plot using the specified grid layout.

# Arguments
- `data`: DataFrame or similar tabular data structure
- `region_col`: Symbol or string specifying the column containing region identifiers
- `plot_func`: Function that takes `(gridlayout, data_subset; kwargs...)` for single-axis plots or
  `(gridlayout, data_subset; processed_axis_kwargs_list)` for multi-axis plots

# Keyword Arguments
- `grid`: GeoGrid object defining the spatial layout (default: `us_state_grid`)
- `figure_kwargs`: NamedTuple passed to `Figure()` constructor
- `common_axis_kwargs`: NamedTuple applied to all axes in each facet. **Important**: To ensure proper
  hiding of axis decorations when `hide_inner_decorations = true`, axis labels (`xlabel`, `ylabel`)
  should be specified here rather than within the plot function.
- `axis_kwargs_list`: Vector of NamedTuples for per-axis specific kwargs. Each element corresponds
  to an axis in the order they are created in the plot function. These are merged with
  `common_axis_kwargs` (per-axis takes precedence). If multiple axes are plotted on the same facet, you
  should set the position within each NamedTuple using the kwarg `yaxisposition` (defaults to `:left`)
- `link_axes`: Symbol controlling axis linking (`:none`, `:x`, `:y`, `:both`)
- `missing_regions`: How to handle regions in grid but not in data (`:skip`, `:empty`, `:error`)
- `hide_inner_decorations`: Bool controlling whether to hide axis decorations on inner facets
  when axes are linked (default: `true`). Only affects linked axes - e.g., if `link_axes = :x`,
  only x-axis decorations are hidden for facets with neighbors below.

# Returns
A Makie Figure object containing the geofaceted plot.

# Example
```julia
using DataFrames, GeoFacetMakie

# Sample data
data = DataFrame(
    state = ["CA", "TX", "NY"],
    population = [39_500_000, 29_000_000, 19_500_000],
    gdp = [3_200_000, 2_400_000, 1_900_000]
)

# Single-axis plot (simplified syntax)
result = geofacet(data, :state, (layout, data; kwargs...) -> begin
    ax = Axis(layout[1, 1]; kwargs...)
    barplot!(ax, [1], data.population)
end;
    common_axis_kwargs = (xlabel = "Index", ylabel = "Population")
)

# Multi-axis plot with common and per-axis kwargs
result = geofacet(data, :state, (layout, data; processed_axis_kwargs_list) -> begin
    ax1 = Axis(layout[1, 1]; processed_axis_kwargs_list[1]...)
    ax2 = Axis(layout[2, 1]; processed_axis_kwargs_list[2]...)
    barplot!(ax1, [1], data.population)
    barplot!(ax2, [1], data.gdp)
end;
    common_axis_kwargs = (titlesize = 12),
    axis_kwargs_list = [
        (xlabel = "Index", ylabel = "Population"),
        (xlabel = "Index", ylabel = "GDP", yscale = log10)
    ]
)
```
"""
function geofacet(
        data,
        region_col,
        plot_func;
        grid = us_state_grid,
        figure_kwargs = NamedTuple(),
        common_axis_kwargs = NamedTuple(),
        axis_kwargs_list = NamedTuple[],
        link_axes = :none,
        missing_regions = :skip,
        hide_inner_decorations = true,
        kwargs...
    )

    # Input validation
    if isempty(data)
        throw(ArgumentError("Data cannot be empty"))
    end

    # Convert region_col to Symbol if it's a string
    region_col_sym = region_col isa String ? Symbol(region_col) : region_col

    if !hasproperty(data, region_col_sym)
        throw(ArgumentError("Column $region_col not found in data"))
    end

    # Validate link_axes parameter
    if !(link_axes in [:none, :x, :y, :both])
        throw(ArgumentError("link_axes must be one of :none, :x, :y, :both"))
    end

    # Validate missing_regions parameter
    if !(missing_regions in [:skip, :empty, :error])
        throw(ArgumentError("missing_regions must be one of :skip, :empty, :error"))
    end


    # Validate axis_kwargs_list parameter
    if !isa(axis_kwargs_list, Vector{<:NamedTuple})
        throw(ArgumentError("axis_kwargs_list must be a Vector of NamedTuples"))
    end

    # Group data by region column using GroupedDataFrame directly
    grouped_data = _prepare_grouped_data(data, region_col_sym)
    available_regions = _get_available_regions(grouped_data, region_col_sym)

    # Get grid dimensions
    max_row, max_col = grid_dimensions(grid)

    # Create figure with appropriate size
    default_figure_kwargs = (size = (max_col * 200, max_row * 150),)
    merged_figure_kwargs = merge(default_figure_kwargs, figure_kwargs)
    fig = Figure(; merged_figure_kwargs...)

    # Create main grid layout
    grid_layout = fig[1, 1] = GridLayout()

    # Track regions with data for return structure (backward compatibility)
    created_gridlayouts = Dict{String, GridLayout}()

    # Handle missing regions check
    if missing_regions == :error
        grid_regions = Set(grid.region)
        data_regions = Set(string.(data[!, region_col_sym]))
        missing_from_data = setdiff(grid_regions, data_regions)
        if !isempty(missing_from_data)
            missing_list = join(missing_from_data, ", ")
            throw(ArgumentError("Missing regions in data: $missing_list"))
        end
    end

    # Choose which grid to use for neighbor detection based on missing_regions setting
    # When missing_regions = :empty, empty axes are created so use full grid
    # When missing_regions = :skip, only data positions have axes so use data-only grid
    neighbor_detection_grid = if missing_regions == :empty
        grid  # Use full grid since empty axes will be created
    else
        # Create a filtered grid containing only positions that have data
        # This is used for neighbor detection to ensure axis decorations are only hidden
        # when there are actual neighboring plots with data
        data_entries = GridEntry[]
        for entry in grid
            if _has_region_data(available_regions, entry.region)
                push!(data_entries, entry)
            end
        end
        StructArray(data_entries)
    end

    # Create axes for all grid positions
    for entry in grid
        region_code, row, col = entry
        # Create axis at grid position
        gl = GridLayout(grid_layout[row, col])
        created_gridlayouts[region_code] = gl

        # Use number of axes from axis_kwargs_list, default to 1 if empty
        num_axes = isempty(axis_kwargs_list) ? 1 : length(axis_kwargs_list)

        # Calculate per-axis decoration hiding kwargs based on neighbor detection and axis linking
        per_axis_decoration_kwargs = NamedTuple[]

        for i in 1:num_axes
            axis_decoration_kwargs = NamedTuple()

            if hide_inner_decorations
                # Only hide x-axis decorations if x-axes are linked AND there's a neighbor below
                if (link_axes == :x || link_axes == :both) && has_neighbor_below(neighbor_detection_grid, region_code)
                    axis_decoration_kwargs = merge(
                        axis_decoration_kwargs, (
                            xticksvisible = false,
                            xticklabelsvisible = false,
                            xlabelvisible = false,
                        )
                    )
                end

                # For y-axis decorations, check ylabel position for this specific axis
                if (link_axes == :y || link_axes == :both)
                    # First merge common and per-axis kwargs to determine ylabel position
                    temp_kwargs = common_axis_kwargs
                    if i <= length(axis_kwargs_list)
                        temp_kwargs = merge(temp_kwargs, axis_kwargs_list[i])
                    end

                    yaxis_position = _get_yaxis_position(temp_kwargs)

                    # Check appropriate neighbor based on ylabel position
                    should_hide_y = if yaxis_position == :right
                        has_neighbor_right(neighbor_detection_grid, region_code)
                    else  # :left (default)
                        has_neighbor_left(neighbor_detection_grid, region_code)
                    end

                    if should_hide_y
                        axis_decoration_kwargs = merge(
                            axis_decoration_kwargs, (
                                yticksvisible = false,
                                yticklabelsvisible = false,
                                ylabelvisible = false,
                            )
                        )
                    end
                end
            end

            push!(per_axis_decoration_kwargs, axis_decoration_kwargs)
        end

        # Merge all kwargs for this region's axes
        processed_axis_kwargs_list = _merge_axis_kwargs(
            common_axis_kwargs,
            axis_kwargs_list,
            per_axis_decoration_kwargs,
            num_axes
        )

        # Check if we have data for this region
        if _has_region_data(available_regions, region_code)
            # Get the actual data for this region
            region_data = _get_region_data(grouped_data, region_col_sym, region_code)

            # Execute plot function with error handling
            try
                # For convenience: if only one set of kwargs, try passing them directly first
                # This allows simpler function signatures for single-axis plots
                if length(processed_axis_kwargs_list) == 1
                    try
                        plot_func(gl, region_data; processed_axis_kwargs_list[1]...)
                    catch e
                        # If that fails, try the explicit API (for backwards compatibility)
                        if e isa UndefKeywordError && e.var == :processed_axis_kwargs_list
                            plot_func(gl, region_data; processed_axis_kwargs_list = processed_axis_kwargs_list)
                        else
                            rethrow(e)
                        end
                    end
                else
                    plot_func(gl, region_data; processed_axis_kwargs_list = processed_axis_kwargs_list)
                end
            catch e
                @warn "Error plotting region $region_code: $e"
                # Continue with other regions
            end
        elseif missing_regions == :empty
            # No data for this region
            # Create empty axis with region label
            # Need to pass all items in processed_axis_kwargs_list to Axis to
            # Correctly handle hiding decorations for empty facets
            for processed_axis_kwargs in processed_axis_kwargs_list
                ax = Axis(gl[1, 1]; title = region_code, processed_axis_kwargs...)
            end
        elseif missing_regions == :skip
            continue
        end
    end

    # Apply axis linking
    if link_axes != :none && !isempty(created_gridlayouts)
        gl_list = collect(values(created_gridlayouts))
        axes_by_position = collect_gl_axes_by_position(gl_list)

        # Link each position's axes separately
        for position_axes in axes_by_position
            if !isempty(position_axes)
                if link_axes == :x
                    linkxaxes!(position_axes...)
                elseif link_axes == :y
                    linkyaxes!(position_axes...)
                elseif link_axes == :both
                    linkxaxes!(position_axes...)
                    linkyaxes!(position_axes...)
                end
            end
        end
    end

    return fig
end

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
