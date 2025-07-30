"""
Documentation for GeoFacetMakie.jl main plotting functionality
"""

@doc """
    geofacet(data, region_col, plot_func;
             grid = us_state_grid1,
             link_axes = :none,
             hide_inner_decorations = true,
             title = "",
             titlekwargs = NamedTuple[],
             figure_kwargs = NamedTuple(),
             common_axis_kwargs = NamedTuple(),
             axis_kwargs_list = NamedTuple[],
             legend_kwargs = NamedTuple(),
             func_kwargs = (missing_regions = :skip,))

Create a geographically faceted plot using the specified grid layout.

# Arguments
- `data`: DataFrame or similar tabular data structure
- `region_col`: Symbol or string specifying the column containing region identifiers
- `plot_func`: Function that takes `(gridlayout, data_subset; kwargs...)` for single-axis plots or
  `(gridlayout, data_subset; processed_axis_kwargs_list)` for multi-axis plots

# Keyword Arguments
- `grid`: GeoGrid object defining the spatial layout (default: `us_state_grid1`)
- `link_axes`: Symbol controlling axis linking (`:none`, `:x`, `:y`, `:both`)
- `hide_inner_decorations`: Bool controlling whether to hide axis decorations on inner facets
  when axes are linked (default: `true`). Only affects linked axes - e.g., if `link_axes = :x`,
  only x-axis decorations are hidden for facets with neighbors below.
- `title`: String for the overall plot title (default: `""` for no title)
- `titlekwargs`: NamedTuple of keyword arguments passed to the title `Label` constructor
- `figure_kwargs`: NamedTuple passed to `Figure()` constructor
- `common_axis_kwargs`: NamedTuple applied to all axes in each facet. **Important**: To ensure proper
  hiding of axis decorations when `hide_inner_decorations = true`, axis labels (`xlabel`, `ylabel`)
  should be specified here rather than within the plot function.
- `axis_kwargs_list`: Vector of NamedTuples for per-axis specific kwargs. Each element corresponds
  to an axis in the order they are created in the plot function. These are merged with
  `common_axis_kwargs` (per-axis takes precedence). If multiple axes are plotted on the same facet, you
  should set the position within each NamedTuple using the kwarg `yaxisposition` (defaults to `:left`)
- `legend_kwargs`: NamedTuple of keyword arguments for legend creation. Special keys:
  - `:title`: Legend title (extracted and passed separately to `Legend`)
  - `:legend_position`: Tuple `(row, col)` specifying legend position in grid layout.
    Use `nothing` for a dimension to use default (e.g., `(nothing, ncols+1)` for rightmost column)
  - All other keys are passed directly to the `Legend` constructor
- `func_kwargs`: NamedTuple of additional keyword arguments passed to the plot function. **Required key**:
  - `:missing_regions`: How to handle regions in grid but not in data (`:skip`, `:empty`, `:error`).
    Defaults to `:skip` if not specified.

# Returns
A Makie Figure object containing the geofaceted plot.

# Examples
```julia
using DataFrames, GeoFacetMakie

# Sample data
data = DataFrame(
    state = ["CA", "TX", "NY"],
    population = [39_500_000, 29_000_000, 19_500_000],
    gdp = [3_200_000, 2_400_000, 1_900_000]
)

# Single-axis plot with title and legend
result = geofacet(data, :state, (gl, data; kwargs...) -> begin
    ax = Axis(gl[1, 1]; kwargs...)
    barplot!(ax, [1], data.population, color = :blue, label = "Population")
    ax.title = data.state[1]  # Set title to state name
    ax.xticksvisible = false  # Clean up x-axis
    ax.xticklabelsvisible = false
end;
    title = "US State Population",
    titlekwargs = (fontsize = 16, color = :darkblue),
    common_axis_kwargs = (ylabel = "Population (M)",),
    legend_kwargs = (title = "Metrics",)
)

# Multi-axis plot with common and per-axis kwargs
result = geofacet(data, :state, (gl, data; processed_axis_kwargs_list) -> begin
    ax1 = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
    ax2 = Axis(gl[2, 1]; processed_axis_kwargs_list[2]...)
    barplot!(ax1, [1], data.population)
    barplot!(ax2, [1], data.gdp)
end;
    common_axis_kwargs = (titlesize = 12,),
    axis_kwargs_list = [
        (xlabel = "Index", ylabel = "Population (M)"),
        (xlabel = "Index", ylabel = "GDP (B)", yscale = log10)
    ],
    figure_kwargs = (size = (1200, 800),)
)

# Time series example with linked y-axes
time_data = DataFrame(
    state = repeat(["CA", "TX", "NY"], inner = 5),
    year = repeat(2019:2023, 3),
    value = rand(15) .* 100
)

result = geofacet(time_data, :state, (gl, data; kwargs...) -> begin
    ax = Axis(gl[1, 1]; kwargs...)
    lines!(ax, data.year, data.value, color = :darkgreen, linewidth = 2)
    ax.title = data.state[1]
end;
    link_axes = :y,  # Link y-axes for comparison
    common_axis_kwargs = (xlabel = "Year", ylabel = "Value"),
    func_kwargs = (missing_regions = :skip,)  # Skip regions not in data
)

# Error handling example
error_data = DataFrame(
    state = ["CA", "TX", "INVALID"],  # INVALID state will be skipped
    value = [1, 2, 3]
)

result = geofacet(error_data, :state, (gl, data; kwargs...) -> begin
    ax = Axis(gl[1, 1]; kwargs...)
    barplot!(ax, [1], data.value, color = :orange)
    ax.title = data.state[1]
end;
    func_kwargs = (missing_regions = :skip,)  # Gracefully skip invalid regions
)
```
""" geofacet

