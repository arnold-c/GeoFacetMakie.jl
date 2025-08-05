# Basic Usage

```@meta
ShareDefaultModule = true
```

As seen in the [Quickstart](../quickstart.md) guide, you can get going pretty quickly with an understanding of [DataFrames.jl](dataframes.juliadata.org/stable/) and [Makie.jl](https://docs.makie.org/stable/).
Let's walk through a couple of relatively simple examples.

## Example 1 - setting up a basic plot

!!! info
    Population bar chart

```@example
using GeoFacetMakie
using DataFrames
using Random

# Choose your preferred Makie backend:
using CairoMakie  # For static plots
CairoMakie.activate!()

# Set random seed for reproducible results
Random.seed!(42)

# Sample population data for US states
sample_data = DataFrame(
    state = [
        "CA", "TX", "NY", "FL", "WA", "PA", "IL", "OH", "GA", "NC",
        "MI", "NJ", "VA", "TN", "AZ", "MA", "IN", "MO", "MD", "WI",
    ],
    population = [
        39.5, 29.1, 19.8, 21.5, 7.6, 13.0, 12.7, 11.8, 10.7, 10.4,
        10.0, 9.3, 8.6, 6.9, 7.3, 7.0, 6.8, 6.2, 6.2, 5.9,
    ],
    gdp_per_capita = [
        75_277, 63_617, 75_131, 47_684, 71_362, 59_195, 65_886,
        54_021, 51_244, 54_578, 48_273, 70_034, 64_607, 52_375,
        45_675, 81_123, 54_181, 53_578, 65_641, 54_610,
    ],
    unemployment_rate = [
        4.2, 3.6, 4.3, 3.2, 4.6, 4.9, 4.2, 4.0, 3.1, 3.9,
        4.3, 4.1, 2.9, 3.3, 3.5, 2.9, 3.2, 2.8, 4.4, 3.2,
    ]
)
```

When creating the plotting function, you need to create a mutating version.
You may want to create a wrapper that creates the figure and then passes it to your mutating version, to confirm that everything plots as you intend with a test subset of the data.

```@example
function barplot_fn!(
    gl,
    data;
    missing_regions, # It's important to have this kwarg
    color = :steelblue,
    axis_kwargs...
)
    ax = Axis(
        gl[1, 1];
        title = data.state[1],
        axis_kwargs...
    )
    barplot!(ax, [1], data.population, color = color)
    return nothing
end

function barplot_fn(
    data;
    missing_regions = :skip,
    color = :steelblue,
    axis_kwargs...
)
    fig = Figure()
    gl = fig[1, 1] = GridLayout()
    barplot_fn!(
        gl,
        data;
        color = color,
        missing_regions = missing_regions,
        axis_kwargs...
    )
    return fig
end
```

Let's show how we can pass some of the axis kwargs through to the `Axis` method call.
If you would like any specific kwargs to be handled within the plotting function body, make sure to explicitly list them in the function signature, for example, `color = :steelblue`.
This is because all other kwargs passed to the user function should be splat within the axis constructor.

```@example
fig_barplot = barplot_fn(
    subset(sample_data, :state => s -> s .== "CA");
    color = :red,
    xlabelvisible = false,
    xticksvisible = false,
    xticklabelsvisible = false,
    ylabel = "Population (M)",
    limits = (nothing, (0, 60))
)
fig_barplot
```

```@example
# Now works with new API
fig_barplot_geofacet = geofacet(
    sample_data,
    :state,
    barplot_fn!;
    link_axes = :both,
    figure_kwargs = (size = (1200, 800),),
    common_axis_kwargs = (
        titlesize = 14,
        ylabel = "Population (M)",
        xlabelvisible = false,
        xticksvisible = false,
        xticklabelsvisible = false,
        limits = (nothing, (0, 60))
    ),
    func_kwargs = ( # pass kwargs to the plotting function here
        missing_regions = :skip,
        color = :coral,
    )
)
fig_barplot_geofacet
```

## Example 2 - linking axes

!!! info
    GDP vs Unemployment

!!! note
    It is also possible to specify the plotting function with an anonymous function


Now let's link axes on a scatter plot.
Because we are dealing with larger numbers, to make the x axis tick labels clearer, let's add some rotation.
We'll also set the `geofacet()` kwarg `hide_inner_decorations = false` to plot all axis ticks and labels on each facet, not just those without a neighbor.

```@example
fig_linked_axes_geofacet = geofacet(
    sample_data, :state,
    (gl, data; missing_regions, axis_kwargs...) -> begin
        ax = Axis(gl[1, 1]; axis_kwargs...)
        scatter!(
            ax, data.gdp_per_capita, data.unemployment_rate,
            color = :coral, markersize = 12
        )
        ax.title = data.state[1]
    end,
    link_axes = :both,  # Link both x and y axes
    figure_kwargs = (size = (1800, 1200),),
    common_axis_kwargs = (
        xlabel = "GDP per capita (\$)",
        ylabel = "Unemployment (%)",
        xticklabelrotation = pi / 4,
    ),
    hide_inner_decorations = false
)
fig_linked_axes_geofacet
```

## Example 3 - time series

!!! info
    Population growth time series, and plot all facets, regardless of whether they contain time series data

```@example
# Create time series data
years = 2010:2023
all_state_data = DataFrame[]

for state in sample_data.state[1:10]  # Use first 10 states for cleaner demo
    base_pop = sample_data[sample_data.state .== state, :population][1]
    growth_rate = 0.005 + 0.01 * rand()  # Random growth rate between 0.5% and 1.5%

    state_data = DataFrame(
        state = fill(state, length(years)),
        year = collect(years),
        population = [base_pop * (1 + growth_rate)^(y - 2023) for y in years]
    )

    # Add this state's data to our collection
    push!(all_state_data, state_data)
end

time_series_data = vcat(all_state_data...)
first(time_series_data, 10)
```

```@example
fig_time_series_geofacet = geofacet(
    time_series_data, :state,
    (gl, data; missing_regions, axis_kwargs...) -> begin
        ax = Axis(gl[1, 1]; axis_kwargs...)
        lines!(
            ax, data.year, data.population,
            color = :darkgreen, linewidth = 2
        )
        ax.title = data.state[1]
    end,
    link_axes = :both,  # Link both x- and y-axes for comparison
    figure_kwargs = (size = (1200, 800),),
    common_axis_kwargs = (
        titlesize = 14,
        xlabel = "Year",
        ylabel = "Population (M)",
        xlabelsize = 12,
        ylabelsize = 12,
        xticklabelsize = 10,
        yticklabelsize = 10,
    ),
    func_kwargs = (missing_regions = :empty,)
)
fig_time_series_geofacet
```

## Example 4 - regions that don't exist in the grid

If your data contains region codes that don't exist in the grid, you should receive an error, unless you set the `additional_regions` kwarg equal to `:warn`.

```@repl
# Create data with some states that don't exist in the grid
error_data = DataFrame(
    state = ["CA", "TX", "INVALID", "FAKE_STATE", "NY"],
    value = [1, 2, 3, 4, 5]
)

fig_additional_regions_geofacet = geofacet( # this errors
    error_data, :state,
    (gl, data; missing_regions, axis_kwargs...) -> begin
        ax = Axis(gl[1, 1]; axis_kwargs...)
        barplot!(ax, [1], data.value, color = :orange)
        ax.title = data.state[1]
    end;
    additional_regions = :error
)

fig_additional_regions_geofacet = geofacet( # This warns and continues
    error_data, :state,
    (gl, data; missing_regions, axis_kwargs...) -> begin
        ax = Axis(gl[1, 1]; axis_kwargs...)
        barplot!(ax, [1], data.value, color = :orange)
        ax.title = data.state[1]
    end;
    additional_regions = :warn
)
```

```@example
fig_additional_regions_geofacet
```

## Example 5 - forgetting `missing_regions`

Your user function should accept the `missing_regions` kwarg (as well as handle it).
If you do not specify it then you should receive an error warning you to rectify this.
This is because the user function must provide the confirmation whether the necessary data for the plot exists and error if `missing_regions` is set to `:error`.

```@repl
geofacet(
    time_series_data, :state,
    (gl, data; axis_kwargs...) -> begin
        ax = Axis(gl[1, 1]; axis_kwargs...)
        lines!(
            ax, data.year, data.population,
            color = :darkgreen, linewidth = 2
        )
        ax.title = data.state[1]
    end,
    link_axes = :y,  # Link y-axes for comparison
    figure_kwargs = (size = (1200, 800),),
    common_axis_kwargs = (
        titlesize = 14,
        xlabel = "Year",
        ylabel = "Population (M)",
        xlabelsize = 12,
        ylabelsize = 12,
        xticklabelsize = 10,
        yticklabelsize = 10,
    ),
    func_kwargs = (missing_regions = :empty,)
)

```
