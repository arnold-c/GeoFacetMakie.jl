# Core Functions

This page documents the main functions and types for creating geofaceted visualizations with GeoFacetMakie.jl.

## Main Plotting Function

```@docs
geofacet
```

## Core Data Types

### GeoGrid

```@docs
GeoGrid
```

### GridEntry

```@docs
GridEntry
```

## Usage Examples

### Basic Geofaceted Plot

```julia
using GeoFacetMakie, DataFrames, CairoMakie

# Sample data
data = DataFrame(
    state = ["CA", "TX", "NY", "FL"],
    population = [39.5, 29.1, 19.8, 21.5],
    year = [2023, 2023, 2023, 2023]
)

# Define plotting function
function plot_bars!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    barplot!(ax, [1], data.population, color = :steelblue)
    ax.title = data.state[1]
end

# Create geofaceted plot
fig = geofacet(data, :state, plot_bars!;
               figure_kwargs = (size = (800, 600),),
               common_axis_kwargs = (ylabel = "Population (M)",))
```

### Multi-Axis Plot

```julia
# Multi-axis plot with different styling per axis
function plot_dual!(gl, data; processed_axis_kwargs_list)
    ax1 = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
    ax2 = Axis(gl[2, 1]; processed_axis_kwargs_list[2]...)
    
    barplot!(ax1, [1], data.population, color = :blue)
    barplot!(ax2, [1], data.gdp, color = :red)
end

fig = geofacet(data, :state, plot_dual!;
               axis_kwargs_list = [
                   (ylabel = "Population (M)",),
                   (ylabel = "GDP (B)", yscale = log10)
               ],
               common_axis_kwargs = (titlesize = 12,))
```

### Custom Grid Usage

```julia
# Create a custom grid
custom_grid = GeoGrid(
    ["A", "B", "C", "D"],
    [1, 1, 2, 2],
    [1, 2, 1, 2]
)

# Use with geofacet
fig = geofacet(data, :region, plot_function!; grid = custom_grid)
```

## Plotting Function Interface

### Function Signature

Plotting functions must follow this signature:

```julia
function my_plot!(gl::GridLayout, data::DataFrame; kwargs...)
    # Create axis in the grid layout
    ax = Axis(gl[1, 1]; kwargs...)

    # Your plotting code here
    lines!(ax, data.x, data.y)

    # Set title to identify the region
    ax.title = data.region[1]

    return nothing
end
```

### Multi-Axis Functions

For plots with multiple axes (e.g., dual y-axes):

```julia
function dual_plot!(gl::GridLayout, data::DataFrame; processed_axis_kwargs_list)
    # First axis
    ax1 = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
    lines!(ax1, data.x, data.y1, color = :blue)

    # Second axis
    ax2 = Axis(gl[1, 1]; processed_axis_kwargs_list[2]...)
    lines!(ax2, data.x, data.y2, color = :red)

    ax1.title = data.region[1]
    return nothing
end
```

### Best Practices

1. **Always mutate**: Function names should end with `!`
2. **Use kwargs**: Accept `kwargs...` for axis styling
3. **Set titles**: Use `ax.title = data.region[1]` to identify regions
4. **Handle edge cases**: Check for empty data, missing values
5. **Return nothing**: Explicitly return `nothing`

## Error Handling

### Missing Regions

```julia
# Skip regions not in grid (default)
fig = geofacet(data, :state, plot_function!; missing_regions = :skip)

# Show empty facets for missing regions
fig = geofacet(data, :state, plot_function!; missing_regions = :empty)

# Throw error if regions are missing
fig = geofacet(data, :state, plot_function!; missing_regions = :error)
```

### Plot Function Errors

The `geofacet` function includes error handling for plot functions. If a plot function fails for a specific region, a warning is issued and plotting continues for other regions:

```julia
function potentially_failing_plot!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    if data.value[1] < 0  # This might fail for some regions
        error("Negative values not supported")
    end
    barplot!(ax, [1], data.value)
end

# This will warn about failed regions but continue plotting others
fig = geofacet(data, :region, potentially_failing_plot!)
```

## Advanced Features

### Axis Linking

```julia
# Link both X and Y axes across facets
fig = geofacet(data, :state, plot_function!; link_axes = :both)

# Link only Y axes (good for comparing magnitudes)
fig = geofacet(data, :state, plot_function!; link_axes = :y)

# Link only X axes (good for time series)
fig = geofacet(data, :state, plot_function!; link_axes = :x)

# No linking (default)
fig = geofacet(data, :state, plot_function!; link_axes = :none)
```

### Legend Creation

```julia
function plot_with_legend!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    barplot!(ax, [1], data.population, color = :blue, label = "Population")
    lines!(ax, [0.5, 1.5], [data.gdp, data.gdp], color = :red, label = "GDP")
    ax.title = data.state[1]
end

fig = geofacet(data, :state, plot_with_legend!;
               legend_kwargs = (
                   title = "Metrics",
                   legend_position = (1, 4)  # Row 1, Column 4
               ))
```

### Decoration Hiding

When axes are linked, inner decorations (tick labels, axis labels) are automatically hidden to reduce clutter:

```julia
# Inner decorations hidden automatically when axes are linked
fig = geofacet(data, :state, plot_function!; 
               link_axes = :y,
               hide_inner_decorations = true,  # Default
               common_axis_kwargs = (
                   xlabel = "Index",  # Only shown on bottom row
                   ylabel = "Value"   # Only shown on left column
               ))
```

## See Also

- [Grid Operations](grids.md) - Working with geographic grids
- [Utilities](utilities.md) - Helper functions and utilities
- [Quick Start Guide](../quickstart.md) - Getting started tutorial
