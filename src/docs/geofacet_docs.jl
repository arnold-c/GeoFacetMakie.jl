"""
Documentation for GeoFacetMakie.jl main plotting functionality
"""

@doc """
    geofacet(data, region_col, plot_func;
             grid = us_state_grid,
             link_axes = :none,
             missing_regions = :skip,
             hide_inner_decorations = true,
             title = "",
             titlekwargs = NamedTuple[],
             figure_kwargs = NamedTuple(),
             common_axis_kwargs = NamedTuple(),
             axis_kwargs_list = NamedTuple[],
             legend_kwargs = NamedTuple(),
             func_kwargs = NamedTuple())

Create a geographically faceted plot using the specified grid layout.

# Arguments
- `data`: DataFrame or similar tabular data structure
- `region_col`: Symbol or string specifying the column containing region identifiers
- `plot_func`: Function that takes `(gridlayout, data_subset; kwargs...)` for single-axis plots or
  `(gridlayout, data_subset; processed_axis_kwargs_list)` for multi-axis plots

# Keyword Arguments
- `grid`: GeoGrid object defining the spatial layout (default: `us_state_grid1`)
- `link_axes`: Symbol controlling axis linking (`:none`, `:x`, `:y`, `:both`)
- `missing_regions`: How to handle regions in grid but not in data (`:skip`, `:empty`, `:error`)
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
- `func_kwargs`: NamedTuple of additional keyword arguments passed to the plot function

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

# Single-axis plot with title and legend
result = geofacet(data, :state, (layout, data; kwargs...) -> begin
    ax = Axis(layout[1, 1]; kwargs...)
    barplot!(ax, [1], data.population, color = :blue, label = "Population")
end;
    title = "US State Population",
    titlekwargs = (fontsize = 16, color = :darkblue),
    common_axis_kwargs = (xlabel = "Index", ylabel = "Population"),
    legend_kwargs = (title = "Metrics", legend_position = (1, 4))
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
    ],
    figure_kwargs = (size = (1200, 800),)
)
```
""" geofacet

