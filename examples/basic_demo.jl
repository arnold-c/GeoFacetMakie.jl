#!/usr/bin/env julia

"""
Basic GeoFacetMakie Demo

This script demonstrates the core functionality of GeoFacetMakie.jl
by creating geographically faceted plots using sample data.

Run this script from the package root directory:
    julia --project examples/basic_demo.jl
"""

#%%
using GeoFacetMakie
using DataFrames
using Random

# Choose your preferred Makie backend:
using GLMakie  # For interactive plots
# using CairoMakie  # For static plots (uncomment this line and comment GLMakie above)

#%%
# Set random seed for reproducible results
Random.seed!(42)

#%%
println("🗺️  GeoFacetMakie Basic Demo")
println("="^50)

# Create sample data for demonstration
println("\n📊 Creating sample data...")

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

println("Created data for $(nrow(sample_data)) states")
println("Columns: $(names(sample_data))")

#%%
# Example 1: Basic bar plot of population
println("\n📈 Example 1: Population by State (Bar Plot)")
println("-"^40)

function barplot_fn(data; axis_kwargs...)
    fig = Figure()
    gl = fig[1, 1] = GridLayout()
    barplot_fn!(gl, data; axis_kwargs...)
    return fig
end

function barplot_fn!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    barplot!(ax, [1], data.population, color = :steelblue)
    ax.title = data.state[1]  # Set title to state name
    ax.xticksvisible = false # Remove x-axis ticks for cleaner look
    ax.xticklabelsvisible = false
    return nothing
end


barplot_fn(
    subset(sample_data, :state => s -> s .== "CA");
    ylabel = "Population (M)"
)

#%%
# Now works with new API
geofacet(
    sample_data,
    :state,
    barplot_fn!;
    link_axes = :both,
    figure_kwargs = (size = (1200, 800),),
    common_axis_kwargs = (titlesize = 14, ylabel = "Population (M)"),
    # hide_inner_decorations = false
)

#%%
try
    result1 = geofacet(
        sample_data,
        :state,
        barplot_fn!;
        link_axes = :both,
        figure_kwargs = (size = (1200, 800),),
        common_axis_kwargs = (titlesize = 14, ylabel = "Population (M)"),
        hide_inner_decorations = false
    )

    println("✅ Successfully created population bar plot")
    println("   - Figure size: $(result1.scene.viewport[].widths)")

    # Save the plot
    save("examples/population_bars.png", result1)
    println("   - Saved as: examples/population_bars.png")

catch e
    println("❌ Error in Example 1: $e")
end

#%%
# Example 2: Scatter plot with linked axes
println("\n💰 Example 2: GDP vs Unemployment (Scatter Plot with Linked Axes)")
println("-"^65)

try
    result2 = geofacet(
        sample_data, :state,
        (gl, data; kwargs...) -> begin
            ax = Axis(gl[1, 1]; kwargs...)
            scatter!(
                ax, data.gdp_per_capita, data.unemployment_rate,
                color = :coral, markersize = 12
            )
            ax.title = data.state[1]
        end,
        link_axes = :both,  # Link both x and y axes
        figure_kwargs = (size = (1800, 1200),),
        common_axis_kwargs = (
            titlesize = 12,
            xlabel = "GDP per capita (\$)",
            ylabel = "Unemployment (%)",
            xlabelsize = 8,
            ylabelsize = 8,
            xticklabelsize = 6,
            yticklabelsize = 6,
        )
    )

    println("✅ Successfully created GDP vs unemployment scatter plot")
    println("   - Axes linked: both x and y")
    println("   - This allows easy comparison across states")

    # Save the plot
    save("examples/gdp_unemployment_scatter.png", result2)
    println("   - Saved as: examples/gdp_unemployment_scatter.png")

catch e
    println("❌ Error in Example 2: $e")
end

#%%
# Example 3: Time series simulation
println("\n📈 Example 3: Simulated Time Series (Population Growth)")
println("-"^50)

try
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

    result3 = geofacet(
        time_series_data, :state,
        (gl, data; kwargs...) -> begin
            ax = Axis(gl[1, 1]; kwargs...)
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
        )
    )

    println("✅ Successfully created time series plot")
    println("   - Years: $(minimum(time_series_data.year)) - $(maximum(time_series_data.year))")
    println("   - Y-axes linked for easy comparison")

    # Save the plot
    save("examples/population_timeseries.png", result3)
    println("   - Saved as: examples/population_timeseries.png")

catch e
    println("❌ Error in Example 3: $e")
end

#%%
# Example 4: Demonstrate error handling
println("\n⚠️  Example 4: Error Handling Demo")
println("-"^35)

try
    # Create data with some states that don't exist in the grid
    error_data = DataFrame(
        state = ["CA", "TX", "INVALID", "FAKE_STATE", "NY"],
        value = [1, 2, 3, 4, 5]
    )

    # This should handle missing regions gracefully
    result4 = geofacet(
        error_data, :state,
        (gl, data; kwargs...) -> begin
            ax = Axis(gl[1, 1]; kwargs...)
            barplot!(ax, [1], data.value, color = :orange)
            ax.title = data.state[1]
        end,
        missing_regions = :skip  # Skip regions not in grid
    )

    save("examples/error-handling_barplot.png", result4)
    println("   - Saved as: examples/error-handling_barplot.png")

    println("✅ Successfully handled missing regions")
    println("   - Invalid states were skipped gracefully")

catch e
    println("❌ Error in Example 4: $e")
end

#%%
# Summary
println("\n🎉 Demo Complete!")
println("="^50)
println("Generated example plots:")
println("  📊 examples/population_bars.png - Bar chart of state populations")
println("  💰 examples/gdp_unemployment_scatter.png - GDP vs unemployment scatter")
println("  📈 examples/population_timeseries.png - Population growth over time")
println("\nTry opening these PNG files to see your geofaceted plots!")
println("\n💡 Next steps:")
println("  - Modify the plot functions to create different visualizations")
println("  - Try different grid layouts (us_state_grid1, us_state_grid2, etc.)")
println("  - Experiment with axis linking options (:none, :x, :y, :both)")
println("  - Add your own data and create custom geofaceted plots!")
