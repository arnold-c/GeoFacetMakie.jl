using Test
using DataFrames
using Dates
using Makie
using GeoFacetMakie

@testset "Geofacet Function Tests" begin

    # Consolidated test data (includes all columns from both original files)
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

    # Simple plot function for testing (GridLayout API)
    function simple_plot_func!(gl, data; axis_kwargs...)
        ax = Axis(gl[1, 1]; axis_kwargs...)
        scatter!(ax, [1], data.value)
        return nothing
    end

    function line_plot_func!(gl, data; axis_kwargs...)
        ax = Axis(gl[1, 1]; axis_kwargs...)
        lines!(ax, data.date, data.cases)
        return nothing
    end
    @testset "Basic Function Signature and Return Structure" begin
        # Test basic function calls
        @test_nowarn geofacet(sample_data, :state, simple_plot_func!)
        @test_nowarn geofacet(sample_data, "state", simple_plot_func!)

        # Test return type structure
        result = geofacet(sample_data, :state, simple_plot_func!)
        @test haskey(result, :figure)
        @test haskey(result, :gls)
        @test haskey(result, :grid_layout)
        @test haskey(result, :data_mapping)
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

    @testset "Data Processing and Grouping" begin
        result = geofacet(sample_data, :state, simple_plot_func!)

        # Check that data was properly grouped and mapped
        @test length(result.data_mapping) == 5  # 5 states in sample data
        @test all(state in keys(result.data_mapping) for state in ["CA", "TX", "NY", "FL", "WA"])

        # Check that GridLayouts were created for data regions
        @test all(state in keys(result.gls) for state in ["CA", "TX", "NY", "FL", "WA"])
    end

    @testset "GridLayout Object Passing" begin
        # Test that plot functions receive GridLayout objects correctly
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

    @testset "Grid Integration" begin
        # Test with default grid
        result1 = geofacet(sample_data, :state, simple_plot_func!)
        @test !isnothing(result1.figure)

        # Test with custom grid
        custom_grid = load_us_state_grid(2)
        result2 = geofacet(sample_data, :state, simple_plot_func!; grid = custom_grid)
        @test !isnothing(result2.figure)

        # Test with contiguous grid
        contiguous_grid = load_us_contiguous_grid()
        result3 = geofacet(sample_data, :state, simple_plot_func!; grid = contiguous_grid)
        @test !isnothing(result3.figure)
    end

    @testset "Plot Function Execution" begin
        # Test that plot function is called for each region
        plot_calls = String[]
        function tracking_plot_func!(gl, data; axis_kwargs...)
            push!(plot_calls, data.state[1])  # Track which state was plotted
            ax = Axis(gl[1, 1]; axis_kwargs...)
            scatter!(ax, [1], data.value)
            return nothing
        end

        result = geofacet(sample_data, :state, tracking_plot_func!)
        @test length(plot_calls) == 5
        @test all(state in plot_calls for state in ["CA", "TX", "NY", "FL", "WA"])
    end

    @testset "Figure and Axis Configuration" begin
        # Test figure_kwargs
        result1 = geofacet(
            sample_data, :state, simple_plot_func!;
            figure_kwargs = (size = (800, 600),)
        )
        @test Tuple(result1.figure.scene.viewport[].widths) == (800, 600)

        # Test axis_kwargs
        result2 = geofacet(
            sample_data, :state, simple_plot_func!;
            axis_kwargs = (ylabel = "Test Label",)
        )
        # Check that GridLayouts were created with the specified kwargs
        @test length(result2.gls) > 0
        # Note: axis_kwargs are passed to the plot function, so we can't directly test them here
        # The plot function is responsible for using them when creating axes
    end

    @testset "Axis Linking" begin
        # Test no linking (default)
        result1 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :none)
        @test !isnothing(result1.figure)

        # Test x-axis linking
        result2 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :x)
        @test !isnothing(result2.figure)

        # Test y-axis linking
        result3 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :y)
        @test !isnothing(result3.figure)

        # Test both axes linking
        result4 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :both)
        @test !isnothing(result4.figure)

        # Test axis linking with multi-axis plots
        function linked_multi_axis_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            lines!(
                ax, [1, 2, 3], [data.value[1], data.value[1] * 1.1, data.value[1] * 1.2],
                color = :steelblue, linewidth = 2
            )
            ax.title = data.state[1]
            return nothing
        end

        result_linked = geofacet(sample_data, :state, linked_multi_axis_func!; link_axes = :both)
        @test !isnothing(result_linked.figure)
        @test length(result_linked.gls) >= 5
    end

    @testset "Missing Regions Handling" begin
        # Create data with only a few states
        limited_data = DataFrame(
            state = ["CA", "TX"],
            value = [100, 200],
            secondary_value = [50, 75]
        )

        # Test skip missing regions (default)
        result1 = geofacet(limited_data, :state, simple_plot_func!; missing_regions = :skip)
        @test length(result1.data_mapping) == 2
        @test haskey(result1.data_mapping, "CA")
        @test haskey(result1.data_mapping, "TX")

        # Test empty GridLayouts for missing regions
        result2 = geofacet(limited_data, :state, simple_plot_func!; missing_regions = :empty)
        @test length(result2.gls) >= 2  # Should have GridLayouts for grid positions

        # Test error on missing regions
        @test_throws Exception geofacet(limited_data, :state, simple_plot_func!; missing_regions = :error)
    end

    @testset "Error Handling" begin
        # Test invalid column name
        @test_throws Exception geofacet(sample_data, :nonexistent_column, simple_plot_func!)

        # Test empty data
        empty_data = DataFrame(state = String[], value = Int[], secondary_value = Int[])
        @test_throws Exception geofacet(empty_data, :state, simple_plot_func!)

        # Test plot function that throws error - should handle gracefully with warnings
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

    @testset "Region Code Matching" begin
        # Test case insensitive matching
        mixed_case_data = DataFrame(
            state = ["ca", "TX", "ny"],  # Mixed case
            value = [100, 200, 150],
            secondary_value = [50, 75, 60]
        )

        result = geofacet(mixed_case_data, :state, simple_plot_func!)
        @test length(result.data_mapping) == 3

        # Test regions not in grid
        invalid_data = DataFrame(
            state = ["CA", "XX", "YY"],  # XX, YY not valid state codes
            value = [100, 200, 150],
            secondary_value = [50, 75, 60]
        )

        # Should handle gracefully and only plot valid regions
        result = geofacet(invalid_data, :state, simple_plot_func!)
        @test haskey(result.data_mapping, "CA")
        @test !haskey(result.data_mapping, "XX")
        @test !haskey(result.data_mapping, "YY")
    end

    @testset "Different Plot Types" begin
        # Test with different plot functions
        function bar_plot_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            barplot!(ax, [1], data.value)
            return nothing
        end
        result1 = geofacet(sample_data, :state, bar_plot_func!)
        @test !isnothing(result1.figure)

        # Test with time series
        result2 = geofacet(time_series_data, :state, line_plot_func!)
        @test !isnothing(result2.figure)

        # Test with multiple series
        function multi_plot_func!(gl, data; axis_kwargs...)
            ax = Axis(gl[1, 1]; axis_kwargs...)
            lines!(ax, data.date, data.cases, color = :blue)
            scatter!(ax, data.date, data.cases, color = :red)
            return nothing
        end
        result3 = geofacet(time_series_data, :state, multi_plot_func!)
        @test !isnothing(result3.figure)

        # Test complex multi-panel layouts (2x2 grid within facets)
        function complex_layout_func!(gl, data; axis_kwargs...)
            # Create a 2x2 grid of axes within the facet
            ax1 = Axis(gl[1, 1]; axis_kwargs...)  # Top-left
            ax2 = Axis(gl[1, 2]; axis_kwargs...)  # Top-right
            ax3 = Axis(gl[2, 1]; axis_kwargs...)  # Bottom-left
            ax4 = Axis(gl[2, 2]; axis_kwargs...)  # Bottom-right

            # Plot different visualizations on each axis
            barplot!(ax1, [1], data.value, color = :steelblue)
            scatter!(ax2, [1], data.secondary_value, color = :coral)
            lines!(ax3, [1, 2], [data.value[1], data.secondary_value[1]], color = :darkgreen)
            heatmap!(
                ax4, reshape(
                    [
                        data.value[1], data.secondary_value[1],
                        data.value[1] * 0.5, data.secondary_value[1] * 0.5,
                    ], 2, 2
                )
            )

            # Configure titles and labels
            ax1.title = "$(data.state[1]) - Bars"
            ax2.title = "$(data.state[1]) - Scatter"
            ax3.title = "$(data.state[1]) - Lines"
            ax4.title = "$(data.state[1]) - Heatmap"

            return nothing
        end
        result4 = geofacet(sample_data, :state, complex_layout_func!)
        @test !isnothing(result4.figure)
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

    @testset "Performance and Memory" begin
        # Test with larger dataset
        large_data = DataFrame(
            state = repeat(["CA", "TX", "NY", "FL", "WA"], 50),
            value = rand(250),
            secondary_value = rand(250),
            date = repeat([Date(2023, 1, 1)], 250)
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

    @testset "Integration with Existing Grid System" begin
        # Test that geofacet works with all available grids
        grids_to_test = [
            load_us_state_grid(1),
            load_us_state_grid(2),
            load_us_state_grid(3),
            load_us_state_grid_without_dc(1),
            load_us_contiguous_grid(),
        ]

        for grid in grids_to_test
            result = geofacet(sample_data, :state, simple_plot_func!; grid = grid)
            @test !isnothing(result.figure)
            @test !isnothing(result.grid_layout)
        end
    end

    @testset "Decoration Hiding" begin
        # Test hide_inner_decorations parameter
        @test_nowarn geofacet(sample_data, :state, simple_plot_func!; hide_inner_decorations = true)
        @test_nowarn geofacet(sample_data, :state, simple_plot_func!; hide_inner_decorations = false)

        # Test that decoration hiding works with different link_axes settings
        @test_nowarn geofacet(
            sample_data, :state, simple_plot_func!;
            link_axes = :none, hide_inner_decorations = true
        )
        @test_nowarn geofacet(
            sample_data, :state, simple_plot_func!;
            link_axes = :x, hide_inner_decorations = true
        )
        @test_nowarn geofacet(
            sample_data, :state, simple_plot_func!;
            link_axes = :y, hide_inner_decorations = true
        )
        @test_nowarn geofacet(
            sample_data, :state, simple_plot_func!;
            link_axes = :both, hide_inner_decorations = true
        )

        # Test with a simple 2x2 grid to verify decoration logic
        #   A B
        #   C D
        simple_entries = [
            GridEntry("A", 1, 1), GridEntry("B", 1, 2),
            GridEntry("C", 2, 1), GridEntry("D", 2, 2),
        ]
        simple_grid = StructArrays.StructArray(simple_entries)
        simple_data = DataFrame(
            state = ["A", "B", "C", "D"],
            value = [1, 2, 3, 4]
        )

        # Track which axis_kwargs are passed to each region
        received_kwargs = Dict{String, Any}()
        function kwargs_tracking_plot_func!(gl, data; axis_kwargs...)
            received_kwargs[data.state[1]] = axis_kwargs
            ax = Axis(gl[1, 1]; axis_kwargs...)
            scatter!(ax, [1], data.value)
            return nothing
        end

        # Test with x-axis linking - should hide x decorations for regions with neighbors below
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :x, hide_inner_decorations = true
        )

        @test haskey(received_kwargs, "A")
        @test haskey(received_kwargs, "B")
        @test haskey(received_kwargs, "C")
        @test haskey(received_kwargs, "D")

        # A and B should have x decorations hidden (they have neighbors below)
        @test received_kwargs["A"] == pairs((xticksvisible = 0, xticklabelsvisible = 0, xlabelvisible = 0))
        @test received_kwargs["B"] == pairs((xticksvisible = 0, xticklabelsvisible = 0, xlabelvisible = 0))
        @test received_kwargs["C"] == pairs(())
        @test received_kwargs["D"] == pairs(())

        # Test with y-axis linking - should hide y decorations for regions with neighbors to the left
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :y, hide_inner_decorations = true
        )

        # B and D should have y decorations hidden (they have neighbors to the left)
        @test received_kwargs["A"] == pairs(())
        @test received_kwargs["B"] == pairs((yticksvisible = 0, yticklabelsvisible = 0, ylabelvisible = 0))
        @test received_kwargs["C"] == pairs(())
        @test received_kwargs["D"] == pairs((yticksvisible = 0, yticklabelsvisible = 0, ylabelvisible = 0))


        # Test with no linking - should not hide any decorations
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :none, hide_inner_decorations = true
        )

        # No decorations should be hidden when axes are not linked
        @test received_kwargs["A"] == pairs(())
        @test received_kwargs["B"] == pairs(())
        @test received_kwargs["C"] == pairs(())
        @test received_kwargs["D"] == pairs(())

        # Test with both linking
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :both, hide_inner_decorations = true
        )

        # A and B should have x decorations hidden (they have neighbors below)
        # B and D should have y decorations hidden (they have neighbors to the left)
        @test received_kwargs["A"] == pairs((xticksvisible = 0, xticklabelsvisible = 0, xlabelvisible = 0))
        @test received_kwargs["B"] == pairs(
            (
                xticksvisible = 0,
                xticklabelsvisible = 0,
                xlabelvisible = 0,
                yticksvisible = 0,
                yticklabelsvisible = 0,
                ylabelvisible = 0,
            )
        )
        @test received_kwargs["C"] == pairs(())
        @test received_kwargs["D"] == pairs((yticksvisible = 0, yticklabelsvisible = 0, ylabelvisible = 0))

        # Test with no inner decoration hiding
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :both, hide_inner_decorations = false
        )

        # No decorations should be hidden when axes are not linked
        @test received_kwargs["A"] == pairs(())
        @test received_kwargs["B"] == pairs(())
        @test received_kwargs["C"] == pairs(())
        @test received_kwargs["D"] == pairs(())
    end

    @testset "Multi-Axis Kwargs API" begin
        # Test new multi-axis kwargs functionality
        test_data = DataFrame(
            state = ["CA", "TX"],
            value1 = [100, 200],
            value2 = [50, 75]
        )

        # Test with common_axis_kwargs only (backward compatible)
        function single_axis_new_api!(gl, data; processed_axis_kwargs_list)
            ax = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
            scatter!(ax, [1], data.value1)
            return nothing
        end

        result1 = geofacet(
            test_data, :state, single_axis_new_api!;
            common_axis_kwargs = (xlabel = "Common X", ylabel = "Common Y")
        )
        @test !isnothing(result1.figure)

        # Test with axis_kwargs_list for multi-axis plots
        function multi_axis_new_api!(gl, data; processed_axis_kwargs_list)
            ax1 = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
            ax2 = Axis(gl[2, 1]; processed_axis_kwargs_list[2]...)

            scatter!(ax1, [1], data.value1)
            scatter!(ax2, [1], data.value2)
            return nothing
        end

        result2 = geofacet(
            test_data, :state, multi_axis_new_api!;
            common_axis_kwargs = (titlesize = 12,),
            axis_kwargs_list = [
                (xlabel = "Value 1", ylabel = "Count 1"),
                (xlabel = "Value 2", ylabel = "Count 2", yscale = log10),
            ]
        )
        @test !isnothing(result2.figure)

        # Test that decoration hiding works with multi-axis
        simple_entries = [GridEntry("A", 1, 1), GridEntry("B", 1, 2)]
        simple_grid = StructArrays.StructArray(simple_entries)

        result3 = geofacet(
            test_data, :state, multi_axis_new_api!;
            grid = simple_grid,
            common_axis_kwargs = (titlesize = 12,),
            axis_kwargs_list = [
                (xlabel = "Value 1", ylabel = "Count 1"),
                (xlabel = "Value 2", ylabel = "Count 2"),
            ],
            link_axes = :y,
            hide_inner_decorations = true
        )
        @test !isnothing(result3.figure)
    end
end
