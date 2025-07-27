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
- `plot_func`: Function that takes `(gridlayout, data_subset; processed_axis_kwargs_list)` and creates plots

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
A NamedTuple with:
- `figure`: The Makie Figure object
- `axes`: Dict mapping region codes to Axis objects
- `grid_layout`: The GridLayout object
- `data_mapping`: Dict showing which regions got data

# Example
```julia
using DataFrames, GeoFacetMakie

# Sample data
data = DataFrame(
    state = ["CA", "TX", "NY"],
    population = [39_500_000, 29_000_000, 19_500_000],
    gdp = [3_200_000, 2_400_000, 1_900_000]
)

# Single-axis plot (backward compatible)
result = geofacet(data, :state, (layout, data; processed_axis_kwargs_list) -> begin
    ax = Axis(layout[1, 1]; processed_axis_kwargs_list[1]...)
    barplot!(ax, [1], data.population)
end; common_axis_kwargs = (xlabel = "Index", ylabel = "Population"))

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
        # Backward compatibility
        axis_kwargs = nothing,
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

    # Group data by region column
    grouped_data = _group_data_by_region(data, region_col_sym)

    # Get grid dimensions
    max_row, max_col = grid_dimensions(grid)

    # Create figure with appropriate size
    default_figure_kwargs = (size = (max_col * 200, max_row * 150),)
    merged_figure_kwargs = merge(default_figure_kwargs, figure_kwargs)
    fig = Figure(; merged_figure_kwargs...)

    # Create main grid layout
    grid_layout = fig[1, 1] = GridLayout()

    # Create axes dictionary and data mapping
    gl_dict = Dict{String, GridLayout}()
    data_mapping = Dict{String, Any}()

    # Handle missing regions check
    if missing_regions == :error
        grid_regions = Set(keys(grid.positions))
        data_regions = Set(string.(data[!, region_col_sym]))
        missing_from_data = setdiff(grid_regions, data_regions)
        if !isempty(missing_from_data)
            missing_list = join(missing_from_data, ", ")
            throw(ArgumentError("Missing regions in data: $missing_list"))
        end
    end

    # Create axes for all grid positions
    for (region_code, (row, col)) in grid.positions
        # Create axis at grid position
        gl = GridLayout(grid_layout[row, col])
        gl_dict[region_code] = gl

        # For backward compatibility, if axis_kwargs_list is empty, use a single axis
        num_axes = isempty(axis_kwargs_list) ? 1 : length(axis_kwargs_list)

        # Calculate per-axis decoration hiding kwargs based on neighbor detection and axis linking
        per_axis_decoration_kwargs = NamedTuple[]

        for i in 1:num_axes
            axis_decoration_kwargs = NamedTuple()

            if hide_inner_decorations
                # Only hide x-axis decorations if x-axes are linked AND there's a neighbor below
                if (link_axes == :x || link_axes == :both) && has_neighbor_below(grid, region_code)
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

                    ylabel_pos = _get_yaxis_position(temp_kwargs)

                    # Check appropriate neighbor based on ylabel position
                    should_hide_y = if ylabel_pos == :right
                        has_neighbor_right(grid, region_code)
                    else  # :left (default)
                        has_neighbor_left(grid, region_code)
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
        region_data = _find_region_data(grouped_data, region_code)

        if !isnothing(region_data)
            # We have data for this region
            data_mapping[region_code] = region_data

            # Execute plot function with error handling
            try
                # For backward compatibility, if axis_kwargs_list is empty, pass the first kwargs as axis_kwargs
                if isempty(axis_kwargs_list)
                    plot_func(gl, region_data; processed_axis_kwargs_list[1]...)
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
            ax = Axis(gl[1, 1]; title = region_code, processed_axis_kwargs_list[1]...)
        elseif missing_regions == :skip
            continue
        end
    end

    # Apply axis linking
    if link_axes != :none && !isempty(gl_dict)
        gl_list = collect(values(gl_dict))
        gl_axes = collect_gl_axes(gl_list)
        if !isempty(gl_axes)
            if link_axes == :x
                linkxaxes!(gl_axes...)
            elseif link_axes == :y
                linkyaxes!(gl_axes...)
            elseif link_axes == :both
                linkxaxes!(gl_axes...)
                linkyaxes!(gl_axes...)
            end
        end
    end

    return (
        figure = fig,
        gls = gl_dict,
        grid_layout = grid_layout,
        data_mapping = data_mapping,
    )
end

"""
    _group_data_by_region(data, region_col)

Group data by region column, handling case-insensitive matching.
"""
function _group_data_by_region(data, region_col)
    # Use DataFrames groupby for efficient grouping
    grouped = groupby(data, region_col)

    # Convert to dictionary with string keys (uppercase for consistency)
    result = Dict{String, Any}()
    for group in grouped
        region_code = string(group[1, region_col])
        # Store with original case but also create uppercase lookup
        result[uppercase(region_code)] = group
        result[region_code] = group  # Also store original case
    end

    return result
end

"""
    _find_region_data(grouped_data, region_code)

Find data for a region, handling case-insensitive matching.
"""
function _find_region_data(grouped_data, region_code)
    # Try exact match first
    if haskey(grouped_data, region_code)
        return grouped_data[region_code]
    end

    # Try uppercase match
    upper_code = uppercase(region_code)
    if haskey(grouped_data, upper_code)
        return grouped_data[upper_code]
    end

    # Try lowercase match
    lower_code = lowercase(region_code)
    if haskey(grouped_data, lower_code)
        return grouped_data[lower_code]
    end

    # No match found
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
