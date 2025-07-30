# Quick Start Guide

Get up and running with GeoFacetMakie.jl in minutes!

## Basic Example

Let's create your first geofaceted plot:

> [!IMPORTANT]
> Need to update this to describe the need to handle `missing_regions` as a `func_kwarg`
> Needs a block in the user function like below:
>
> ```julia
>     if length(years) == 0 && missing_regions != :empty
>         error("No valid data points found for state $state and serotype $serotype.")
>     end
> ```


> [!IMPORTANT]
> Need to note that all kwargs that modify the label in the Legend e.g., markersize, need to be handled by the users function and passed as part of `func_kwarg`
>
> ```julia
> function user_func(...; legendmarkersize=16)
> ...
> scatter!(
>   ax,
>   x_values,
>   y_values,
>   color = color,
>   markersize = markersize ,
>   label = "series a" => (; markersize = legendmarkersize),
> )
> ...
> end
>
> ```


```julia
using GeoFacetMakie, DataFrames, CairoMakie

# Sample data for US states
data = DataFrame(
    state = ["CA", "TX", "NY", "FL", "WA", "PA"],
    population = [39.5, 29.1, 19.8, 21.5, 7.6, 13.0],
    gdp_per_capita = [75_277, 63_617, 75_131, 47_684, 71_362, 59_195]
)

# Define a simple plotting function
function plot_population!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; title = data.state[1], kwargs...)
    barplot!(ax, [1], data.population, color = :steelblue)
end

# Load a reliable grid
grid = load_grid_from_csv("us_state_grid1")

# Create the geofaceted plot
fig = geofacet(
    data, :state, plot_population!;
    grid = grid,
    link_axes = :y,
    figure_kwargs = (size = (800, 600),),
    common_axis_kwargs = (
        ylabel = "Population (M)",
        xticksvisible = false,
        xticklabelsvisible = false,
    )
)

fig
```

That's it! You've created your first geofaceted visualization.

## Understanding the Components

### 1. Data Structure

GeoFacetMakie.jl works with any data structure that can be grouped by a geographic identifier:

```julia
# Your data needs:
# - A geographic column (state, country, region, etc.)
# - One or more data columns to visualize
data = DataFrame(
    state = ["CA", "TX", "NY"],  # Geographic identifier
    value1 = [10, 20, 15],       # Data to plot
    value2 = [5, 8, 12]          # More data (optional)
)
```

### 2. Plotting Function

The plotting function defines what gets drawn in each facet:

```julia
function my_plot!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)  # Create axis in grid layout
    # Your plotting code here
    lines!(ax, data.x, data.y)     # Example: line plot
    ax.title = data.region[1]       # Set title to region name
end
```

**Key points:**
- Function must be **mutating** (end with `!`)
- Takes `gl` (GridLayout), `data` (subset for this region), and `kwargs`
- Create an `Axis` in the GridLayout
- Set `ax.title` to identify the region

### 3. The `geofacet` Function

```julia
geofacet(data, grouping_column, plotting_function; options...)
```

**Required arguments:**
- `data` - Your dataset
- `grouping_column` - Column name for geographic grouping (e.g., `:state`)
- `plotting_function` - Function that creates plots for each region

**Common options:**
- `figure_kwargs` - Figure size, resolution, etc.
- `common_axis_kwargs` - Axis labels, styling applied to all facets
- `link_axes` - Link axes across facets (`:x`, `:y`, `:both`, `:none`)

## Common Patterns

### Scatter Plots

```julia
function plot_scatter!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    scatter!(ax, data.gdp_per_capita, data.population,
             color = :coral, markersize = 15)
    ax.title = data.state[1]
end

# Load a reliable grid
grid = load_grid_from_csv("us_state_grid1")

geofacet(
    data, :state, plot_scatter!;
    grid = grid,
    figure_kwargs = (size = (800, 600),),
    common_axis_kwargs = (
        xlabel = "GDP per capita (\$)",
        ylabel = "Population (M)"
    ),
    link_axes = :both
)
```

### Time Series

```julia
# Create time series data
years = 2020:2023
ts_data = DataFrame()
for state in ["CA", "TX", "NY"]
    for year in years
        push!(ts_data, (
            state = state,
            year = year,
            value = 100 + 10*rand() + (year-2020)*5
        ))
    end
end

function plot_timeseries!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    lines!(ax, data.year, data.value,
           color = :darkgreen, linewidth = 3)
    ax.title = data.state[1]
end

# Load a reliable grid
grid = load_grid_from_csv("us_state_grid1")

geofacet(
    ts_data, :state, plot_timeseries!;
    grid = grid,
    figure_kwargs = (size = (800, 400),),
    common_axis_kwargs = (
        xlabel = "Year",
        ylabel = "Value"
    ),
    link_axes = :y
)
```

## Customization Options

### Figure Styling

```julia
geofacet(data, :state, plot_function!;
    figure_kwargs = (
        size = (1200, 800),      # Width x Height in pixels
        fontsize = 12,           # Base font size
        backgroundcolor = :white # Background color
    )
)
```

### Axis Styling

```julia
geofacet(data, :state, plot_function!;
    common_axis_kwargs = (
        xlabel = "X Label",
        ylabel = "Y Label",
        titlesize = 14,
        xlabelsize = 12,
        ylabelsize = 12,
        xticklabelsize = 10,
        yticklabelsize = 10
    )
)
```

### Axis Linking

Control how axes are linked across facets:

```julia
# Link both X and Y axes (default)
link_axes = :both

# Link only X axes (good for time series)
link_axes = :x

# Link only Y axes (good for comparing magnitudes)
link_axes = :y

# No linking (each facet independent)
link_axes = :none
```

## Built-in Geographic Grids

GeoFacetMakie.jl includes many pre-defined grids from the geofacet collection:

```julia
# List available grids
available_grids = list_available_grids()
println("Available grids: ", join(available_grids[1:5], ", "), "...")

# Load a specific grid
grid = load_grid_from_csv("us_state_grid1")

# Use with geofacet
geofacet(data, :state, plot_function!; grid = grid)
```

Common US state grids include:
- `us_state_grid1` - Standard US state layout
- `us_state_grid2` - Alternative US state arrangement
- `us_state_grid3` - Compact US state layout
- `us_state_contiguous_grid1` - Contiguous US only (no AK, HI)

## Error Handling

Handle missing regions gracefully:

```julia
# Skip regions not in the grid
geofacet(data, :state, plot_function!; missing_regions = :skip)

# Show empty facets for missing regions
geofacet(data, :state, plot_function!; missing_regions = :empty)
```

## Next Steps

Now that you understand the basics:

1. **[Basic Usage Tutorial](tutorials/basic_usage.md)** - Detailed walkthrough with more examples
2. **[Customization Tutorial](tutorials/customization.md)** - Advanced styling and customization
3. **[Examples Gallery](examples/gallery.md)** - See real-world examples
4. **[API Reference](api/core.md)** - Complete function documentation

## Need Help?

- Check the [Troubleshooting Guide](guides/troubleshooting.md)
- Browse [Examples](examples/gallery.md) for inspiration
- Ask questions in [GitHub Issues](https://github.com/arnold-c/GeoFacetMakie.jl/issues)
