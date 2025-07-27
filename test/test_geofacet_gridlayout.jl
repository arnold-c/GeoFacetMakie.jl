using Test
using DataFrames
using Dates
using Makie
using GeoFacetMakie

@testset "Geofacet GridLayout Functionality Tests" begin

    # Sample test data
    sample_data = DataFrame(
        state = ["CA", "TX", "NY", "FL", "WA"],
        value = [100, 200, 150, 180, 120],
        secondary_value = [50, 75, 60, 90, 55],
        date = [Date(2023, 1, 1), Date(2023, 1, 1), Date(2023, 1, 1), Date(2023, 1, 1), Date(2023, 1, 1)]
    )

    time_series_data = DataFrame(
        state = repeat(["CA", "TX", "NY"], inner = 3),
        date = repeat([Date(2023, 1, 1), Date(2023, 2, 1), Date(2023, 3, 1)], 3),
        cases = [100, 110, 120, 200, 210, 220, 150, 160, 170],
        deaths = [5, 6, 7, 10, 11, 12, 8, 9, 10]
    )

    @testset "GridLayout Object Passing" begin
        # Test that plot functions receive GridLayout objects
        received_objects = []

        function gridlayout_test_func!(gl, data; axis_kwargs...)
            push!(received_objects, gl)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            scatter!(ax, [1], data.value)
            return nothing
        end

        result = geofacet(sample_data, :state, gridlayout_test_func!)

        # Verify that all received objects are GridLayout instances
        @test length(received_objects) == 5  # One for each state
        @test all(obj isa GridLayout for obj in received_objects)

        # Verify the result structure includes GridLayout references
        @test haskey(result, :gls)
        @test isa(result.gls, Dict)
        @test length(result.gls) >= 5  # At least one for each state with data
        @test all(gl isa GridLayout for gl in values(result.gls))
    end

    @testset "Single Axis Creation in GridLayout" begin
        # Test basic single axis creation within GridLayout
        function single_axis_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            barplot!(ax, [1], data.value, color = :steelblue)
            ax.title = data.state[1]
            ax.ylabel = "Value"
            return nothing
        end

        result = geofacet(sample_data, :state, single_axis_func!)

        @test !isnothing(result.figure)
        @test isa(result.grid_layout, GridLayout)
        @test length(result.data_mapping) == 5

        # Test that we can access the created axes through the GridLayout structure
        @test length(result.gls) >= 5
    end

    @testset "Multi-Axis Creation in GridLayout" begin
        # Test creating multiple axes within a single GridLayout (facet)
        function multi_axis_func!(gl, data; axis_kwargs...)
            # Create two axes in the same GridLayout
            ax1 = Axis(gl[1, 1]; axis_kwargs...)
            ax2 = Axis(gl[2, 1]; axis_kwargs...)

            # Plot different data on each axis
            barplot!(ax1, [1], data.value, color = :steelblue)
            barplot!(ax2, [1], data.secondary_value, color = :coral)

            # Configure axes
            ax1.title = data.state[1]
            ax1.ylabel = "Primary Value"
            ax2.ylabel = "Secondary Value"

            return nothing
        end

        result = geofacet(sample_data, :state, multi_axis_func!)

        @test !isnothing(result.figure)
        @test isa(result.grid_layout, GridLayout)
        @test length(result.data_mapping) == 5

        # Verify that the GridLayouts can accommodate multiple axes
        @test length(result.gls) >= 5
    end

    @testset "Dual Y-Axis Implementation" begin
        # Test creating dual y-axis plots similar to the examples
        function dual_axis_func!(gl, data; axis_kwargs...)
            # Create primary axis
            ax1 = Axis(gl[1, 1]; axis_kwargs...)

            # Create secondary axis overlaid
            ax2 = Axis(gl[1, 1]; axis_kwargs...)

            # Plot on primary axis
            lines!(
                ax1, [1, 2, 3], [data.value[1], data.value[1] * 1.1, data.value[1] * 1.2],
                color = :steelblue, linewidth = 2
            )

            # Configure secondary axis
            ax2.yaxisposition = :right
            ax2.xticksvisible = false
            ax2.xticklabelsvisible = false
            ax2.leftspinevisible = false
            ax2.bottomspinevisible = false
            ax2.topspinevisible = false

            # Plot on secondary axis
            lines!(
                ax2, [1, 2, 3], [data.secondary_value[1], data.secondary_value[1] * 0.9, data.secondary_value[1] * 1.1],
                color = :firebrick, linewidth = 2
            )

            # Configure labels
            ax1.title = data.state[1]
            ax1.ylabel = "Primary (Left)"
            ax1.ylabelcolor = :steelblue
            ax2.ylabel = "Secondary (Right)"
            ax2.ylabelcolor = :firebrick

            return nothing
        end

        result = geofacet(sample_data, :state, dual_axis_func!)

        @test !isnothing(result.figure)
        @test length(result.data_mapping) == 5
        @test length(result.gls) >= 5
    end

    @testset "GridLayout Error Handling" begin
        # Test error handling when plot function fails with GridLayout
        error_count = 0

        function error_plot_func!(gl, data; axis_kwargs...)
            error_count += 1
            if error_count <= 2  # First two calls will error
                error("Simulated plotting error")
            else
                # Successful plot for remaining calls
                ax = Axis(gl[1, 1]; axis_kwargs...)
                scatter!(ax, [1], data.value)
                return nothing
            end
        end

        # Should handle errors gracefully and continue with other facets
        result = geofacet(sample_data, :state, error_plot_func!)

        @test !isnothing(result)
        @test haskey(result, :figure)
        @test haskey(result, :gls)
        @test length(result.data_mapping) == 5  # Data mapping should still be complete
    end

    @testset "GridLayout with Axis Linking" begin
        # Test that axis linking works with GridLayout-based plots
        function linked_plot_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            lines!(
                ax, [1, 2, 3], [data.value[1], data.value[1] * 1.1, data.value[1] * 1.2],
                color = :steelblue, linewidth = 2
            )
            ax.title = data.state[1]
            return nothing
        end

        # Test x-axis linking
        result_x = geofacet(sample_data, :state, linked_plot_func!; link_axes = :x)
        @test !isnothing(result_x.figure)
        @test length(result_x.gls) >= 5

        # Test y-axis linking
        result_y = geofacet(sample_data, :state, linked_plot_func!; link_axes = :y)
        @test !isnothing(result_y.figure)
        @test length(result_y.gls) >= 5

        # Test both axes linking
        result_both = geofacet(sample_data, :state, linked_plot_func!; link_axes = :both)
        @test !isnothing(result_both.figure)
        @test length(result_both.gls) >= 5
    end

    @testset "GridLayout Return Structure Validation" begin
        # Test the structure of returned GridLayout objects
        function simple_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            scatter!(ax, [1], data.value)
            return nothing
        end

        result = geofacet(sample_data, :state, simple_func!)

        # Test return structure
        @test haskey(result, :figure)
        @test haskey(result, :gls)
        @test haskey(result, :grid_layout)
        @test haskey(result, :data_mapping)

        # Test types
        @test isa(result.figure, Figure)
        @test isa(result.gls, Dict)
        @test isa(result.grid_layout, GridLayout)
        @test isa(result.data_mapping, Dict)

        # Test that gls contains GridLayout objects for each region
        @test length(result.gls) >= 5
        @test all(gl isa GridLayout for gl in values(result.gls))

        # Test that GridLayouts exist for states with data
        for state in ["CA", "TX", "NY", "FL", "WA"]
            @test haskey(result.gls, state)
            @test isa(result.gls[state], GridLayout)
        end
    end

    @testset "GridLayout with Missing Regions" begin
        # Test GridLayout behavior with missing regions
        limited_data = DataFrame(
            state = ["CA", "TX"],
            value = [100, 200]
        )

        function simple_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            barplot!(ax, [1], data.value)
            ax.title = data.state[1]
            return nothing
        end

        # Test skip missing regions
        result_skip = geofacet(limited_data, :state, simple_func!; missing_regions = :skip)
        @test length(result_skip.data_mapping) == 2
        @test haskey(result_skip.data_mapping, "CA")
        @test haskey(result_skip.data_mapping, "TX")

        # Test empty regions - should create GridLayouts but not call plot function
        result_empty = geofacet(limited_data, :state, simple_func!; missing_regions = :empty)
        @test length(result_empty.gls) >= 2  # Should have GridLayouts for grid positions
    end

    @testset "GridLayout Axis Collection and Linking" begin
        # Test the internal axis collection functionality
        function multi_axis_func!(gl, data; axis_kwargs...)
            ax1 = Axis(gl[1, 1]; axis_kwargs...)
            ax2 = Axis(gl[2, 1]; axis_kwargs...)

            lines!(ax1, [1, 2, 3], [data.value[1], data.value[1] * 1.1, data.value[1] * 1.2])
            lines!(ax2, [1, 2, 3], [data.secondary_value[1], data.secondary_value[1] * 0.9, data.secondary_value[1] * 1.1])

            return nothing
        end

        result = geofacet(sample_data, :state, multi_axis_func!; link_axes = :x)

        @test !isnothing(result.figure)
        @test length(result.gls) >= 5

        # Test that the collect_gl_axes function can find axes in GridLayouts
        gl_list = collect(values(result.gls))
        axes_found = GeoFacetMakie.collect_gl_axes(gl_list)

        # Should find multiple axes (2 per GridLayout * number of GridLayouts)
        @test length(axes_found) >= 10  # At least 2 axes per state
        @test all(ax isa Axis for ax in axes_found)
    end

    @testset "GridLayout Performance with Large Data" begin
        # Test GridLayout performance with larger datasets
        large_data = DataFrame(
            state = repeat(["CA", "TX", "NY", "FL", "WA"], 50),
            value = rand(250),
            secondary_value = rand(250)
        )

        function performance_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            scatter!(ax, data.value, data.secondary_value, markersize = 4)
            ax.title = data.state[1]
            return nothing
        end

        # Should handle larger datasets without issues
        @test_nowarn geofacet(large_data, :state, performance_func!)
    end
end

