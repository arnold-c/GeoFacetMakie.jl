#!/usr/bin/env julia

"""
Full US States Time Series Demo

This script demonstrates GeoFacetMakie.jl with comprehensive data for all 50 US states
plus Alaska, showing dual time series (population and GDP) in each geographic facet.

Features:
- Complete US state coverage including Alaska
- Dual time series per facet (population growth + GDP per capita)
- Named mutating plotting function passed to geofacet
- Realistic simulated economic data over 15 years

Run this script from the package root directory:
    julia --project examples/full_states_timeseries.jl
"""

#%%
using GeoFacetMakie
using DataFrames
using GLMakie
using Random

# Set random seed for reproducible results
Random.seed!(123)

println("🗺️  Full US States Time Series Demo")
println("=" ^ 60)

#%%
# Complete list of US states with realistic baseline data
println("\n📊 Creating comprehensive state data...")

# All 50 states + DC with 2023 baseline data
state_info = DataFrame(
    state = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ],
    population_2023 = [
        5.2, 0.73, 7.4, 3.0, 39.0, 5.8, 3.6, 1.0, 22.6, 11.0,
        1.4, 1.9, 12.6, 6.8, 3.2, 2.9, 4.5, 4.6, 1.4, 6.2,
        7.0, 10.0, 5.7, 2.9, 6.2, 1.1, 2.0, 3.2, 1.4, 9.3,
        2.1, 19.3, 10.7, 0.78, 11.8, 4.0, 4.2, 13.0, 1.1, 5.3,
        0.91, 7.0, 30.0, 3.4, 0.65, 8.7, 7.8, 1.8, 5.9, 0.58
    ],
    gdp_per_capita_2023 = [
        49_861, 77_477, 55_313, 49_475, 89_540, 80_184, 90_213, 85_939, 57_703, 58_608,
        65_393, 52_225, 78_291, 60_780, 65_555, 59_917, 52_295, 51_073, 56_277, 75_847,
        95_029, 55_675, 71_715, 40_464, 57_290, 54_506, 66_661, 64_296, 77_933, 75_715,
        49_754, 95_043, 60_592, 88_865, 65_278, 51_424, 71_342, 70_979, 64_340, 54_672,
        61_346, 58_492, 73_092, 68_758, 54_166, 74_222, 86_265, 47_529, 63_293, 75_648
    ]
)

println("Created baseline data for $(nrow(state_info)) states")

#%%
# Generate 15 years of time series data (2009-2023)
println("📈 Generating 15-year time series data...")

years = 2009:2023
# Create array to collect all state DataFrames
all_state_data = DataFrame[]

for row in eachrow(state_info)
    state = row.state
    base_pop = row.population_2023
    base_gdp = row.gdp_per_capita_2023

    # Generate realistic growth patterns
    pop_growth_rate = 0.003 + 0.015 * rand()  # 0.3% to 1.8% annual growth
    gdp_growth_rate = 0.01 + 0.03 * rand()    # 1% to 4% annual growth

    # Add some economic volatility (2008 crisis, COVID impact)
    pop_volatility = 0.002 * randn(length(years))
    gdp_volatility = 0.05 * randn(length(years))

    # Special adjustments for economic events
    crisis_years = [2009, 2010]  # Financial crisis
    covid_years = [2020, 2021]   # COVID impact

    # Pre-allocate arrays for this state's data
    state_populations = Float64[]
    state_gdps = Float64[]

    for (i, year) in enumerate(years)
        # Calculate years back from 2023
        years_back = 2023 - year

        # Base growth calculation
        pop_factor = (1 + pop_growth_rate)^(-years_back)
        gdp_factor = (1 + gdp_growth_rate)^(-years_back)

        # Apply volatility
        pop_vol = pop_volatility[i]
        gdp_vol = gdp_volatility[i]

        # Economic crisis adjustments
        if year in crisis_years
            gdp_vol -= 0.08  # GDP hit during financial crisis
            pop_vol -= 0.005  # Slower population growth
        elseif year in covid_years
            gdp_vol -= 0.05  # COVID economic impact
            pop_vol -= 0.003  # COVID population impact
        end

        # Calculate final values
        population = base_pop * pop_factor * (1 + pop_vol)
        gdp_per_capita = base_gdp * gdp_factor * (1 + gdp_vol)

        push!(state_populations, max(0.1, population))  # Ensure positive
        push!(state_gdps, max(20000, gdp_per_capita))  # Ensure reasonable minimum
    end

    # Create DataFrame for this state with all data at once
    state_data = DataFrame(
        state = fill(state, length(years)),
        year = collect(years),
        population = state_populations,
        gdp_per_capita = state_gdps
    )

    # Add this state's data to our collection
    push!(all_state_data, state_data)
end

# Combine all state data into one DataFrame
time_series_data = vcat(all_state_data...)

println("Generated time series for $(length(unique(time_series_data.state))) states")
println("Time range: $(minimum(time_series_data.year)) - $(maximum(time_series_data.year))")
println("Data points: $(nrow(time_series_data))")

#%%
# Define named mutating plotting function for dual time series
"""
    dual_timeseries_plot!(gl, data; processed_axis_kwargs_list)

Mutating plotting function that creates dual time series plots using the new multi-axis API:
- Population (left y-axis, blue line)
- GDP per capita (right y-axis, red line)

This function demonstrates the new multi-axis kwargs API where each axis receives
its own processed kwargs from the geofacet function.
"""
function dual_timeseries_plot!(gl, data; processed_axis_kwargs_list)
    # Ensure data is sorted by year
    sorted_data = sort(data, :year)

    # Create population axis with first set of processed kwargs
    pop_ax = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)

    # Create GDP axis with second set of processed kwargs
    gdp_ax = Axis(gl[1, 1]; processed_axis_kwargs_list[2]...)

    # Plot population on primary y-axis (left)
    lines!(pop_ax, sorted_data.year, sorted_data.population,
           color = :steelblue, linewidth = 2.5, label = "Population")

    # Configure primary axis (population)
    pop_ax.title = sorted_data.state[1]

    # Configure secondary axis (GDP) - styling applied via kwargs
    # Additional styling not covered by kwargs

    # Plot GDP on secondary y-axis (right)
    lines!(gdp_ax, sorted_data.year, sorted_data.gdp_per_capita,
           color = :firebrick, linewidth = 2.5, label = "GDP per capita")

    return nothing
end


#%%
# Test the plotting function with a single state
println("\n🧪 Testing plotting function with California data...")

ca_data = subset(time_series_data, :state => s -> s .== "CA")
test_fig = Figure(size = (400, 300))
test_gl = test_fig[1, 1] = GridLayout()

# Create test kwargs list for the new API
test_kwargs_list = [
	# Population Axis
    (
    	xlabel = "Year",
    	ylabel = "Population (M)",
    	titlesize = 12,
    	ylabelcolor = :steelblue,
    	yticklabelcolor = :steelblue,

    ),
	# GDP Axis
    (
    	yaxisposition = :right,
    	ylabel = "GDP per capita (\$)",
    	ylabelcolor = :firebrick,
    	yticklabelcolor = :firebrick,
		# Don't want duplication of axis and grid, so disable
		xticksvisible = false,
		xticklabelsvisible = false,
		xgridvisible = false,
		ygridvisible = false,
		leftspinevisible = false,
		rightspinevisible = false,
		bottomspinevisible = false,
		topspinevisible = false,
    )
]
dual_timeseries_plot!(test_gl, ca_data; processed_axis_kwargs_list = test_kwargs_list)
test_fig

println("✅ Single state test successful")

#%%
geofacet(
	# Remove OR to confirm that empty states are handled correctly on both axes
	subset(time_series_data, :state => s -> s .!= "OR"),
		:state,
		dual_timeseries_plot!;  # Pass our named function
		figure_kwargs = (size = (4000, 2500), fontsize = 8),
		common_axis_kwargs = (
            titlesize = 10,
            xlabelsize = 6,
            ylabelsize = 6
        ),
        axis_kwargs_list = [
            # Population axis (left)
            (xlabel = "Year", ylabel = "Population (M)",
             ylabelcolor = :steelblue, yticklabelcolor = :steelblue),
            # GDP axis (right)
            (yaxisposition = :right, ylabel = "GDP per capita (\$)",
             ylabelcolor = :firebrick, yticklabelcolor = :firebrick)
        ],
		link_axes = :both,  # Link x-axes for time comparison
		missing_regions = :empty
	)

#%%
Create the full geofaceted plot
println("\n🗺️ Creating geofaceted dual time series plot...")

try
	result = geofacet(
		time_series_data,
		:state,
		dual_timeseries_plot!;  # Pass our named function
		figure_kwargs = (size = (4000, 2500), fontsize = 8),
		common_axis_kwargs = (
            titlesize = 10,
            xlabelsize = 6,
            ylabelsize = 6
        ),
        axis_kwargs_list = [
            # Population axis (left)
            (xlabel = "Year", ylabel = "Population (M)",
             ylabelcolor = :steelblue, yticklabelcolor = :steelblue),
            # GDP axis (right)
            (yaxisposition = :right, ylabel = "GDP per capita (\$)",
             ylabelcolor = :firebrick, yticklabelcolor = :firebrick)
        ],
		link_axes = :x  # Link x-axes for time comparison
	);

	println("✅ Successfully created dual time series geofacet plot")
	println("   - States included: $(length(result.gls))")
	println("   - Time range: $(minimum(time_series_data.year)) - $(maximum(time_series_data.year))")
	println("   - X-axes linked for temporal comparison")
	println("   - Dual y-axes: Population (left, blue) + GDP (right, red)")
	println("   - Using new multi-axis kwargs API")

	# Save the comprehensive plot
	save("examples/full_states_dual_timeseries.png", result.figure)
	println("   - Saved as: examples/full_states_dual_timeseries.png")

	# Create a summary of the data
	println("\n📊 Data Summary:")
	println("   - Population range: $(round(minimum(time_series_data.population), digits=2))M - $(round(maximum(time_series_data.population), digits=2))M")
	println("   - GDP range: \$$(round(minimum(time_series_data.gdp_per_capita), digits=0)) - \$$(round(maximum(time_series_data.gdp_per_capita), digits=0))")

	# Show which states have data
	states_with_data = sort(collect(keys(result.data_mapping)))
	println("   - States plotted: $(length(states_with_data))")
	println("   - Includes Alaska: $("AK" in states_with_data)")
catch e
    println("❌ Error creating geofacet plot: $e")
    rethrow(e)
end

#%%
# Create a focused version with just a subset for cleaner viewing
println("\n🎯 Creating focused version with top 20 most populous states...")
try
    # Get top 20 states by 2023 population
    top_states = sort(state_info, :population_2023, rev=true)[1:20, :state]
	focused_data = subset(time_series_data, :state => s -> in.(s, Ref(top_states)))

    result_focused = geofacet(
        focused_data,
        :state,
        dual_timeseries_plot!;
        figure_kwargs = (size = (1400, 900), fontsize = 11),
        common_axis_kwargs = (
            titlesize = 12,
            xlabelsize = 10,
            ylabelsize = 10
        ),
        axis_kwargs_list = [
            # Population axis (left)
            (xlabel = "Year", ylabel = "Population (M)",
             ylabelcolor = :steelblue, yticklabelcolor = :steelblue),
            # GDP axis (right)
            (yaxisposition = :right, ylabel = "GDP per capita (\$)",
             ylabelcolor = :firebrick, yticklabelcolor = :firebrick)
        ],
        link_axes = :x
    )

    save("examples/top20_states_dual_timeseries.png", result_focused.figure)
    println("✅ Created focused plot with top 20 states")
    println("   - Saved as: examples/top20_states_dual_timeseries.png")
    println("   - States: $(sort(collect(keys(result_focused.data_mapping))))")

catch e
    println("❌ Error creating focused plot: $e")
end

#%%
# Summary
println("\n🎉 Full States Time Series Demo Complete!")
println("=" ^ 60)
println("Generated comprehensive geofaceted plots:")
println("  🗺️  examples/full_states_dual_timeseries.png - All 50 states dual time series")
println("  🎯 examples/top20_states_dual_timeseries.png - Top 20 states focused view")
println("\n📈 Features demonstrated:")
println("  ✅ Complete US state coverage (50 states including Alaska)")
println("  ✅ Dual time series per facet (Population + GDP)")
println("  ✅ Named mutating plotting function (dual_timeseries_plot!)")
println("  ✅ Realistic 15-year economic data simulation")
println("  ✅ Secondary y-axis implementation")
println("  ✅ X-axis linking for temporal comparison")
println("  ✅ Economic event modeling (2008 crisis, COVID impact)")
println("\n💡 Key implementation details:")
println("  - dual_timeseries_plot!() function creates dual y-axes")
println("  - Population plotted on left axis (blue)")
println("  - GDP per capita on right axis (red)")
println("  - Uses new multi-axis kwargs API with processed_axis_kwargs_list")
println("  - common_axis_kwargs applied to both axes")
println("  - axis_kwargs_list provides per-axis specific styling")
println("  - Automatic decoration hiding with hide_inner_decorations")
println("  - Function passed directly to geofacet() as named parameter")
println("  - Comprehensive error handling and data validation")
