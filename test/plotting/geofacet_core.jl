"""
Tests for main geofacet plotting functionality
"""

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

    # Simple plot function for testing (GridLayout API) - using new simplified syntax
    function simple_plot_func!(gl, data; kwargs...)
        ax = Axis(gl[1, 1]; kwargs...)
        scatter!(ax, [1], data.value)
        return nothing
    end

    function line_plot_func!(gl, data; kwargs...)
        ax = Axis(gl[1, 1]; kwargs...)
        lines!(ax, data.date, data.cases)
        return nothing
    end

    # Multi-axis plot function for testing - using explicit processed_axis_kwargs_list
    function multi_axis_plot_func!(gl, data; processed_axis_kwargs_list)
        ax1 = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
        ax2 = Axis(gl[2, 1]; processed_axis_kwargs_list[2]...)
        scatter!(ax1, [1], data.value)
        scatter!(ax2, [1], data.secondary_value)
        return nothing
    end
    @testset "Basic Function Signature and Return Structure" begin
        # Test basic function calls
        @test_nowarn geofacet(sample_data, :state, simple_plot_func!)
        @test_nowarn geofacet(sample_data, "state", simple_plot_func!)

        # Test return type structure - now returns Figure directly
        result = geofacet(sample_data, :state, simple_plot_func!)
        @test isa(result, Figure)

        # Test that the figure contains the expected grid layout structure
        @test !isnothing(result.layout)
        @test isa(result.layout, GridLayout)
    end

    @testset "Data Processing and Grouping" begin
        result = geofacet(sample_data, :state, simple_plot_func!)

        # Check that the figure was created successfully
        @test isa(result, Figure)
        @test !isnothing(result.layout)

        # Verify that the figure contains content (plots were created)
        @test !isempty(result.layout.content)

        # Verify 5 separate facets are created and each contains an Axis
        @test length(result.content) == 5
        @test result.content[1] isa Axis
    end

    @testset "GridLayout Object Passing" begin
        # Test that plot functions receive GridLayout objects correctly
        received_objects = []

        function gridlayout_test_func!(gl, data; kwargs...)
            push!(received_objects, gl)
            ax = Axis(gl[1, 1]; kwargs...)
            scatter!(ax, [1], data.value)
            return nothing
        end

        result = geofacet(sample_data, :state, gridlayout_test_func!)

        # Verify that all received objects are GridLayout instances
        @test length(received_objects) == 5  # One for each state
        @test all(obj isa GridLayout for obj in received_objects)

        # Verify the result is a Figure
        @test isa(result, Figure)
        @test !isnothing(result.layout)
    end

    @testset "Single Axis Creation in GridLayout" begin
        # Test basic single axis creation within GridLayout
        function single_axis_func!(gl, data; kwargs...)
            ax = Axis(gl[1, 1]; kwargs...)
            barplot!(ax, [1], data.value, color = :steelblue)
            ax.title = data.state[1]
            ax.ylabel = "Value"
            return nothing
        end

        result = geofacet(sample_data, :state, single_axis_func!)

        @test isa(result, Figure)
        @test !isnothing(result.layout)
    end

    @testset "Multi-Axis Creation in GridLayout" begin
        # Test creating multiple axes within a single GridLayout (facet)
        function multi_axis_func!(gl, data; processed_axis_kwargs_list)
            # Create two axes in the same GridLayout
            ax1 = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
            ax2 = Axis(gl[2, 1]; processed_axis_kwargs_list[1]...)

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
        @test isa(result, Figure)
        @test !isnothing(result.layout)

        # Verify 5 separate facets are created and each contains 2 Axes
        @test length(result.content) == 5 * 2
        @test result.content[1] isa Axis


        facet_gls = filter(
            c -> !isempty(c.content.content),
            result.layout.content[1].content.content
        )
        @test length(facet_gls) == 5

        for facet in facet_gls
            @test length(facet.content.content) == 2
        end

    end

    @testset "Dual Y-Axis Implementation" begin
        # Test creating dual y-axis plots similar to the examples
        function dual_axis_func!(gl, data; kwargs...)
            # Create primary axis
            ax1 = Axis(gl[1, 1]; kwargs...)

            # Create secondary axis overlaid
            ax2 = Axis(gl[1, 1]; kwargs...)

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
        @test isa(result, Figure)
        @test !isnothing(result.layout)
    end

    @testset "Grid Integration" begin
        # Test with default grid
        result1 = geofacet(sample_data, :state, simple_plot_func!)
        @test isa(result1, Figure)

        # Test with custom grid
        custom_grid = load_us_state_grid(2)
        result2 = geofacet(sample_data, :state, simple_plot_func!; grid = custom_grid)
        @test isa(result2, Figure)

        # Test with contiguous grid
        contiguous_grid = load_us_contiguous_grid()
        result3 = geofacet(sample_data, :state, simple_plot_func!; grid = contiguous_grid)
        @test isa(result3, Figure)
    end

    @testset "Plot Function Execution" begin
        # Test that plot function is called for each region
        plot_calls = String[]
        function tracking_plot_func!(gl, data; kwargs...)
            push!(plot_calls, data.state[1])  # Track which state was plotted
            ax = Axis(gl[1, 1]; kwargs...)
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
        @test Tuple(result1.scene.viewport[].widths) == (800, 600)

        # Test common_axis_kwargs
        result2 = geofacet(
            sample_data, :state, simple_plot_func!;
            common_axis_kwargs = (ylabel = "Test Label",)
        )
        # Check that the figure was created successfully
        @test isa(result2, Figure)
        # Note: common_axis_kwargs are passed to the plot function, so we can't directly test them here
        # The plot function is responsible for using them when creating axes
    end

    @testset "Axis Linking" begin
        # Test no linking (default)
        result1 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :none)
        @test isa(result1, Figure)

        # Test x-axis linking
        result2 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :x)
        @test isa(result2, Figure)

        # Test y-axis linking
        result3 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :y)
        @test isa(result3, Figure)

        # Test both axes linking
        result4 = geofacet(time_series_data, :state, line_plot_func!; link_axes = :both)
        @test isa(result4, Figure)

        # Test axis linking with multi-axis plots
        function linked_multi_axis_func!(gl, data; kwargs...)
            ax = Axis(gl[1, 1]; kwargs...)
            lines!(
                ax, [1, 2, 3], [data.value[1], data.value[1] * 1.1, data.value[1] * 1.2],
                color = :steelblue, linewidth = 2
            )
            ax.title = data.state[1]
            return nothing
        end

        result_linked = geofacet(sample_data, :state, linked_multi_axis_func!; link_axes = :both)
        @test isa(result_linked, Figure)
        @test !isnothing(result_linked.layout)
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
        @test isa(result1, Figure)
        @test !isnothing(result1.layout)

        # Test empty GridLayouts for missing regions
        result2 = geofacet(limited_data, :state, simple_plot_func!; missing_regions = :empty)
        @test isa(result2, Figure)
        @test !isnothing(result2.layout)

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
        function error_plot_func!(gl, data; kwargs...)
            error_count += 1
            if error_count <= 2  # First two calls will error
                error("Simulated plotting error")
            else
                # Successful plot for remaining calls
                ax = Axis(gl[1, 1]; kwargs...)
                scatter!(ax, [1], data.value)
                return nothing
            end
        end

        # Should handle errors gracefully and continue with other facets
        result = geofacet(sample_data, :state, error_plot_func!)
        @test isa(result, Figure)
        @test !isnothing(result.layout)
    end

    @testset "Region Code Matching" begin
        # Test case insensitive matching
        mixed_case_data = DataFrame(
            state = ["ca", "TX", "ny"],  # Mixed case
            value = [100, 200, 150],
            secondary_value = [50, 75, 60]
        )

        result = geofacet(mixed_case_data, :state, simple_plot_func!)
        @test isa(result, Figure)

        # Test regions not in grid
        invalid_data = DataFrame(
            state = ["CA", "XX", "YY"],  # XX, YY not valid state codes
            value = [100, 200, 150],
            secondary_value = [50, 75, 60]
        )

        # Should handle gracefully and only plot valid regions
        result = geofacet(invalid_data, :state, simple_plot_func!)
        @test isa(result, Figure)
        @test !isnothing(result.layout)
    end

    @testset "Different Plot Types" begin
        # Test with different plot functions
        function bar_plot_func!(gl, data; kwargs...)
            ax = Axis(gl[1, 1]; kwargs...)
            barplot!(ax, [1], data.value)
            return nothing
        end
        result1 = geofacet(sample_data, :state, bar_plot_func!)
        @test isa(result1, Figure)

        # Test with time series
        result2 = geofacet(time_series_data, :state, line_plot_func!)
        @test isa(result2, Figure)

        # Test with multiple series
        function multi_plot_func!(gl, data; kwargs...)
            ax = Axis(gl[1, 1]; kwargs...)
            lines!(ax, data.date, data.cases, color = :blue)
            scatter!(ax, data.date, data.cases, color = :red)
            return nothing
        end
        result3 = geofacet(time_series_data, :state, multi_plot_func!)
        @test isa(result3, Figure)

        # Test complex multi-panel layouts (2x2 grid within facets)
        function complex_layout_func!(gl, data; kwargs...)
            # Create a 2x2 grid of axes within the facet
            ax1 = Axis(gl[1, 1]; kwargs...)  # Top-left
            ax2 = Axis(gl[1, 2]; kwargs...)  # Top-right
            ax3 = Axis(gl[2, 1]; kwargs...)  # Bottom-left
            ax4 = Axis(gl[2, 2]; kwargs...)  # Bottom-right

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
        @test isa(result4, Figure)
    end

    @testset "GridLayout Axis Collection and Linking" begin
        # Test the internal axis collection functionality
        function multi_axis_func!(gl, data; kwargs...)
            ax1 = Axis(gl[1, 1]; kwargs...)
            ax2 = Axis(gl[2, 1]; kwargs...)

            lines!(ax1, [1, 2, 3], [data.value[1], data.value[1] * 1.1, data.value[1] * 1.2])
            lines!(ax2, [1, 2, 3], [data.secondary_value[1], data.secondary_value[1] * 0.9, data.secondary_value[1] * 1.1])

            return nothing
        end

        result = geofacet(sample_data, :state, multi_axis_func!; link_axes = :x)

        @test isa(result, Figure)
        @test !isnothing(result.layout)

        facet_gls = filter(
            c -> !isempty(c.content.content),
            result.layout.content[1].content.content
        )
        @test length(facet_gls) == 5

        for facet in facet_gls
            @test length(facet.content.content) == 2
        end


        # Test that the figure contains the expected structure
        # Note: Since we no longer return gls directly, we test that the figure was created successfully
        # and contains the expected layout structure
        @test !isempty(result.layout.content)
    end

    @testset "Performance and Memory" begin
        # Test with larger dataset
        large_data = DataFrame(
            state = repeat(["CA", "TX", "NY", "FL", "WA"], 50),
            value = rand(250),
            secondary_value = rand(250),
            date = repeat([Date(2023, 1, 1)], 250)
        )

        function performance_func!(gl, data; kwargs...)
            ax = Axis(gl[1, 1]; kwargs...)
            scatter!(ax, data.value, data.secondary_value, markersize = 4)
            ax.title = data.state[1]
            return nothing
        end

        # Should handle larger datasets without issues
        result = geofacet(large_data, :state, performance_func!)
        @test isa(result, Figure)
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
            @test isa(result, Figure)
            @test !isnothing(result.layout)
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
        function kwargs_tracking_plot_func!(gl, data; kwargs...)
            received_kwargs[data.state[1]] = kwargs
            ax = Axis(gl[1, 1]; kwargs...)
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
        @test received_kwargs["A"] == pairs((xticksvisible = false, xticklabelsvisible = false, xlabelvisible = false))
        @test received_kwargs["B"] == pairs((xticksvisible = false, xticklabelsvisible = false, xlabelvisible = false))
        @test received_kwargs["C"] == pairs(NamedTuple())
        @test received_kwargs["D"] == pairs(NamedTuple())

        # Test with y-axis linking - should hide y decorations for regions with neighbors to the left
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :y, hide_inner_decorations = true
        )

        # B and D should have y decorations hidden (they have neighbors to the left)
        @test received_kwargs["A"] == pairs(NamedTuple())
        @test received_kwargs["B"] == pairs((yticksvisible = false, yticklabelsvisible = false, ylabelvisible = false))
        @test received_kwargs["C"] == pairs(NamedTuple())
        @test received_kwargs["D"] == pairs((yticksvisible = false, yticklabelsvisible = false, ylabelvisible = false))


        # Test with no linking - should not hide any decorations
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :none, hide_inner_decorations = true
        )

        # No decorations should be hidden when axes are not linked
        @test received_kwargs["A"] == pairs(NamedTuple())
        @test received_kwargs["B"] == pairs(NamedTuple())
        @test received_kwargs["C"] == pairs(NamedTuple())
        @test received_kwargs["D"] == pairs(NamedTuple())

        # Test with both linking
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :both, hide_inner_decorations = true
        )

        # A and B should have x decorations hidden (they have neighbors below)
        # B and D should have y decorations hidden (they have neighbors to the left)
        @test received_kwargs["A"] == pairs((xticksvisible = false, xticklabelsvisible = false, xlabelvisible = false))
        @test received_kwargs["B"] == pairs(
            (
                xticksvisible = false,
                xticklabelsvisible = false,
                xlabelvisible = false,
                yticksvisible = false,
                yticklabelsvisible = false,
                ylabelvisible = false,
            )
        )
        @test received_kwargs["C"] == pairs(NamedTuple())
        @test received_kwargs["D"] == pairs((yticksvisible = false, yticklabelsvisible = false, ylabelvisible = false))

        # Test with no inner decoration hiding
        empty!(received_kwargs)
        geofacet(
            simple_data, :state, kwargs_tracking_plot_func!;
            grid = simple_grid, link_axes = :both, hide_inner_decorations = false
        )

        # No decorations should be hidden when hide_inner_decorations = false
        @test received_kwargs["A"] == pairs(NamedTuple())
        @test received_kwargs["B"] == pairs(NamedTuple())
        @test received_kwargs["C"] == pairs(NamedTuple())
        @test received_kwargs["D"] == pairs(NamedTuple())
    end

    @testset "Single vs Multi-Axis Kwargs API" begin
        # Test new convenience API for single-axis plots
        test_data = DataFrame(
            state = ["CA", "TX"],
            value1 = [100, 200],
            value2 = [50, 75]
        )

        # Test single-axis with simplified kwargs... syntax
        function single_axis_simple!(gl, data; kwargs...)
            ax = Axis(gl[1, 1]; kwargs...)
            scatter!(ax, [1], data.value1)
            return nothing
        end

        result1 = geofacet(
            test_data, :state, single_axis_simple!;
            common_axis_kwargs = (xlabel = "Simple X", ylabel = "Simple Y")
        )
        @test isa(result1, Figure)

        # Test single-axis with explicit processed_axis_kwargs_list (should still work)
        function single_axis_explicit!(gl, data; processed_axis_kwargs_list)
            ax = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
            scatter!(ax, [1], data.value1)
            return nothing
        end

        result2 = geofacet(
            test_data, :state, single_axis_explicit!;
            common_axis_kwargs = (xlabel = "Explicit X", ylabel = "Explicit Y")
        )
        @test isa(result2, Figure)

        # Test multi-axis with axis_kwargs_list (requires processed_axis_kwargs_list)
        function multi_axis_explicit!(gl, data; processed_axis_kwargs_list)
            ax1 = Axis(gl[1, 1]; processed_axis_kwargs_list[1]...)
            ax2 = Axis(gl[2, 1]; processed_axis_kwargs_list[2]...)

            scatter!(ax1, [1], data.value1)
            scatter!(ax2, [1], data.value2)
            return nothing
        end

        result3 = geofacet(
            test_data, :state, multi_axis_explicit!;
            common_axis_kwargs = (titlesize = 12,),
            axis_kwargs_list = [
                (xlabel = "Value 1", ylabel = "Count 1"),
                (xlabel = "Value 2", ylabel = "Count 2", yscale = log10),
            ]
        )
        @test isa(result3, Figure)

        # Test that decoration hiding works with both APIs
        simple_entries = [GridEntry("A", 1, 1), GridEntry("B", 1, 2)]
        simple_grid = StructArrays.StructArray(simple_entries)

        # Single-axis with decoration hiding
        result4 = geofacet(
            test_data, :state, single_axis_simple!;
            grid = simple_grid,
            common_axis_kwargs = (xlabel = "Test X", ylabel = "Test Y"),
            link_axes = :y,
            hide_inner_decorations = true
        )
        @test isa(result4, Figure)

        # Multi-axis with decoration hiding
        result5 = geofacet(
            test_data, :state, multi_axis_explicit!;
            grid = simple_grid,
            common_axis_kwargs = (titlesize = 12,),
            axis_kwargs_list = [
                (xlabel = "Value 1", ylabel = "Count 1"),
                (xlabel = "Value 2", ylabel = "Count 2"),
            ],
            link_axes = :y,
            hide_inner_decorations = true
        )
        @test isa(result5, Figure)
    end

    # Helper functions for legend testing
    function has_legend(fig::Figure)
        # Check all content in the figure's layout recursively
        return _find_legend_recursive(fig.layout)
    end

    function _find_legend_recursive(layout)
        for content in layout.content
            if content.content isa Legend
                return true
            elseif content.content isa GridLayout
                if _find_legend_recursive(content.content)
                    return true
                end
            end
        end
        return false
    end

    @testset "Legend Creation Tests" begin
        # Test data
        test_data = DataFrame(
            state = ["CA", "TX", "NY"],
            value = [100, 200, 150]
        )

        # Get expected grid dimensions
        grid = load_us_state_grid(1)  # or whatever default grid is used
        expected_regions = length(unique(test_data.state))

        @testset "No Legend When legend_kwargs Empty" begin
            function unlabeled_plot!(gl, data; kwargs...)
                ax = Axis(gl[1, 1]; kwargs...)
                scatter!(ax, [1], data.value)
                return nothing
            end

            fig = geofacet(test_data, :state, unlabeled_plot!)

            @test !has_legend(fig)
        end

        @testset "Legend Created With Labeled Plots" begin
            function labeled_plot!(gl, data; kwargs...)
                ax = Axis(gl[1, 1]; kwargs...)
                scatter!(ax, [1], data.value, label = "Test Data")
                return nothing
            end

            fig = geofacet(
                test_data, :state, labeled_plot!;
                legend_kwargs = (title = "My Legend",)
            )

            @test has_legend(fig)
        end

        @testset "Warning When Legend Requested But No Labels" begin
            function unlabeled_plot!(gl, data; kwargs...)
                ax = Axis(gl[1, 1]; kwargs...)
                scatter!(ax, [1], data.value)  # No label
                return nothing
            end

            # Test with warning capture
            fig = @test_logs (:warn, r"Legend requested but no plots with labels found") geofacet(
                test_data, :state, unlabeled_plot!;
                legend_kwargs = (title = "My Legend",)
            )

            # Test 1: No Legend should be created despite legend_kwargs
            @test !has_legend(fig)

        end

        @testset "Legend Positioning" begin
            function labeled_plot!(gl, data; kwargs...)
                ax = Axis(gl[1, 1]; kwargs...)
                scatter!(ax, [1], data.value, label = "Test Data")
                return nothing
            end

            # Test custom legend position
            fig = geofacet(
                test_data, :state, labeled_plot!;
                legend_kwargs = (title = "My Legend", legend_position = (1, 1))
            )

            @test has_legend(fig)
        end
    end
end
