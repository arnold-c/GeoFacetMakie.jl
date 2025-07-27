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
    geofacet(data, region_col, plot_func;
             grid = us_state_grid,
             figure_kwargs = NamedTuple(),
             axis_kwargs = NamedTuple(),
             link_axes = :none,
             missing_regions = :skip,
             kwargs...)

Create a geographically faceted plot using the specified grid layout.

# Arguments
- `data`: DataFrame or similar tabular data structure
- `region_col`: Symbol or string specifying the column containing region identifiers
- `plot_func`: Function that takes `(gridlayout, data_subset)` and creates plots

# Keyword Arguments
- `grid`: GeoGrid object defining the spatial layout (default: `us_state_grid`)
- `figure_kwargs`: NamedTuple passed to `Figure()` constructor
- `axis_kwargs`: NamedTuple passed to each `Axis()` constructor
- `link_axes`: Symbol controlling axis linking (`:none`, `:x`, `:y`, `:both`)
- `missing_regions`: How to handle regions in grid but not in data (`:skip`, `:empty`, `:error`)

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
    population = [39_500_000, 29_000_000, 19_500_000]
)

# Create bar plots for each state (simple single-axis plot)
result = geofacet(data, :state, (layout, data) -> begin
    ax = Axis(layout[1, 1])
    barplot!(ax, [1], data.population)
end)

# Display the figure
result.figure

# For complex multi-axis plots:
result = geofacet(data, :state, (layout, data) -> begin
    ax1 = Axis(layout[1, 1])
    ax2 = Axis(layout[2, 1])
    barplot!(ax1, [1], data.population)
    barplot!(ax2, [1], data.gdp)
end)
```
"""
function geofacet(
        data,
        region_col,
        plot_func;
        grid = us_state_grid,
        figure_kwargs = NamedTuple(),
        axis_kwargs = NamedTuple(),
        link_axes = :none,
        missing_regions = :skip,
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

        # Check if we have data for this region
        region_data = _find_region_data(grouped_data, region_code)

        if !isnothing(region_data)
            # We have data for this region
            data_mapping[region_code] = region_data

            # Execute plot function with error handling
            try
                plot_func(gl, region_data; axis_kwargs...)
            catch e
                @warn "Error plotting region $region_code: $e"
                # Continue with other regions
            end
        else
            # No data for this region
            if missing_regions == :empty
                # Create empty axis with region label
                text!(ax, 0.5, 0.5, text = region_code, align = (:center, :center))
                xlims!(ax, 0, 1)
                ylims!(ax, 0, 1)
            elseif missing_regions == :skip
                # Leave axis empty
                hide_all_decorations!(gl)
            end
        end
    end

    # Apply axis linking
    if link_axes != :none && !isempty(gl_dict)
        gl_list = collect(values(gl_dict))
        gl_axes = collect_gl_axes(gl_list)
        if link_axes == :x
            linkxaxes!(gl_axes...)
        elseif link_axes == :y
            linkyaxes!(gl_axes...)
        elseif link_axes == :both
            linkxaxes!(gl_axes...)
            linkyaxes!(gl_axes...)
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

function collect_gl_axes(layouts::Vector{GridLayout})
    axes = Axis[]

    for layout in layouts, content in layout.content
        if content.content isa Axis
            push!(axes, content.content)
        end
    end

    return axes
end
