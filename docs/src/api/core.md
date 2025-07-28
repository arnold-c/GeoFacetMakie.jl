# Core Functions

This page documents the main functions and types in GeoFacetMakie.jl.

## Main Functions

### `geofacet`

```@docs
GeoFacetMakie
geofacet
```

The primary function for creating geofaceted visualizations. This function takes your data, groups it by a geographic identifier, and creates a grid of plots arranged according to geographic relationships.

#### Basic Usage

```julia
geofacet(data, grouping_column, plotting_function; options...)
```

#### Parameters

**Required:**
- `data`: DataFrame or similar tabular data structure
- `grouping_column`: Symbol or string specifying the column containing geographic identifiers
- `plotting_function`: Function that creates plots for each geographic region

**Optional Keyword Arguments:**
- `grid`: Custom geographic grid (DataFrame with `code`, `row`, `col` columns)
- `figure_kwargs`: Named tuple of arguments passed to `Figure()`
- `common_axis_kwargs`: Named tuple of arguments applied to all axes
- `axis_kwargs_list`: Vector of named tuples for multi-axis plots
- `link_axes`: Symbol specifying axis linking (`:x`, `:y`, `:both`, `:none`)
- `missing_regions`: Symbol specifying how to handle missing regions (`:skip`, `:empty`, `:error`)

#### Examples

**Basic bar chart:**
```julia
geofacet(data, :state, plot_function!;
         figure_kwargs = (size = (800, 600),),
         common_axis_kwargs = (ylabel = "Population",))
```

**Time series with linked x-axes:**
```julia
geofacet(timeseries_data, :state, timeseries_plot!;
         link_axes = :x,
         common_axis_kwargs = (xlabel = "Year", ylabel = "Value"))
```

**Dual-axis plot:**
```julia
geofacet(data, :state, dual_axis_plot!;
         axis_kwargs_list = [
             (ylabel = "Population", ylabelcolor = :blue),
             (yaxisposition = :right, ylabel = "GDP", ylabelcolor = :red)
         ])
```

## Data Structures

### `GeoGrid`

```julia
GeoGrid
```

Represents a geographic grid layout for arranging plots.

See [`Geogrid`](@ref) and [Grids](grids.md) for more details, but briefly

#### Structure

A `GeoGrid` is typically a DataFrame with the following columns:

- `code`: Geographic identifiers (e.g., "CA", "TX", "NY")
- `row`: Grid row positions (integers starting from 1)
- `col`: Grid column positions (integers starting from 1)
- `name`: (Optional) Full region names
- Additional metadata columns as needed

#### Built-in Grids

GeoFacetMakie.jl includes several pre-defined grids:

- `us_state_grid1`: Standard US state layout
- `us_state_grid2`: Alternative US state arrangement
- `us_state_grid3`: Compact US state layout
- `us_state_contiguous_grid1`: Contiguous US only (excludes AK, HI)

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

### Common Errors

[Grid issues](grids.md)

**Invalid plotting function:**
```julia
# Error: Plotting function must be mutating (end with !)
# Solution: Rename function to end with !
function my_plot!(gl, data; kwargs...)  # Correct
```

**Axis kwargs conflicts:**
```julia
# Error: Conflicting axis arguments
# Solution: Use either common_axis_kwargs OR axis_kwargs_list, not both
```

### Debugging Tips

1. **Test with small data**: Start with 2-3 regions
2. **Check grid structure**: Ensure `code`, `row`, `col` columns exist
3. **Validate plotting function**: Test function independently
4. **Use meaningful titles**: Set `ax.title` for identification
5. **Check data types**: Ensure numeric columns are numeric

## Performance Considerations

### Large Datasets

For datasets with many regions or time points:

```julia
# Sample data for development
sampled_data = data[sample(1:nrow(data), 1000), :]

# Use efficient plotting
function efficient_plot!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    # Minimize allocations
    lines!(ax, data.x, data.y, linewidth = 1)
    ax.title = data.region[1]
    return nothing
end
```

### Memory Usage

- Use appropriate data types (`Float32` vs `Float64`)
- Consider data aggregation for visualization
- Use `CairoMakie` for static plots to reduce memory

### Rendering Performance

- Choose appropriate figure sizes
- Limit the number of plot elements per facet
- Use efficient Makie plotting functions

## Integration with Makie Ecosystem

### Backends

GeoFacetMakie.jl should work with all Makie backends:

```julia
using CairoMakie    # Static plots
using GLMakie       # Interactive plots
using WGLMakie      # Web-based plots
```

### Themes

Apply Makie themes to geofaceted plots:

```julia
with_theme(theme_dark()) do
    geofacet(data, :state, plot_fn!)
end
```

Alternatively, you can set the theme at the start of your file (or somewhere in your package module):

```julia
"""
    theme_adjustments()

Create custom theme adjustments for Makie plots.

Returns a `Theme` object with customized font sizes and styling for axes and colorbars,
designed to improve readability in scientific publications.

# Returns
- `Theme`: A Makie theme with adjusted font sizes and bold labels.
"""
function theme_adjustments()
    return Theme(;
        fontsize = 24,
        Axis = (;
            xlabelsize = 28,
            ylabelsize = 28,
            xlabelfont = :bold,
            ylabelfont = :bold,
        ),
        Colorbar = (;
            labelsize = 24,
            labelfont = :bold,
        ),
    )
end

"""
Custom theme combining theme adjustments with minimal theme.

This theme is used as the base for all plots in the package, providing consistent
styling across different visualization functions.
"""
custom_theme = merge(theme_adjustments(), theme_minimal())

set_theme!(
    custom_theme;
    fontsize = 16,
    linewidth = 6,
    markersize = 20,
)

update_theme!(; size = (1300, 800))
GLMakie.activate!()
```

### Plot Types

All Makie plot types are supported:

- `lines!`, `scatter!`, `barplot!`
- `heatmap!`, `contour!`, `surface!`
- `hist!`, `boxplot!`, `violin!`
- Custom plot recipes

## See Also

# - [Basic Usage Tutorial](../tutorials/basic_usage.md) - Learn the fundamentals
# - [Advanced Features](../tutorials/advanced_features.md) - Multi-axis and complex plots
# - [Examples Gallery](../examples/gallery.md) - Real-world examples
# - [Grid Operations](grids.md) - Working with geographic grids
- [Utilities](utilities.md) - Helper functions and tools
