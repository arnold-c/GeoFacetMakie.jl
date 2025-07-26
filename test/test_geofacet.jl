using Test
using DataFrames
using Dates
using Makie
using GeoFacetMakie

@testset "Geofacet Function Tests" begin
    
    # Sample test data
    sample_data = DataFrame(
        state = ["CA", "TX", "NY", "FL", "WA"],
        value = [100, 200, 150, 180, 120],
        date = [Date(2023, 1, 1), Date(2023, 1, 1), Date(2023, 1, 1), Date(2023, 1, 1), Date(2023, 1, 1)]
    )
    
    time_series_data = DataFrame(
        state = repeat(["CA", "TX", "NY"], inner=3),
        date = repeat([Date(2023, 1, 1), Date(2023, 2, 1), Date(2023, 3, 1)], 3),
        cases = [100, 110, 120, 200, 210, 220, 150, 160, 170]
    )
    
    # Simple plot function for testing
    simple_plot_func = (ax, data) -> scatter!(ax, [1], data.value)
    line_plot_func = (ax, data) -> lines!(ax, data.date, data.cases)
    
    @testset "Basic Function Signature" begin
        @test_nowarn geofacet(sample_data, :state, simple_plot_func)
        
        # Test with string column name
        @test_nowarn geofacet(sample_data, "state", simple_plot_func)
        
        # Test return type structure
        result = geofacet(sample_data, :state, simple_plot_func)
        @test haskey(result, :figure)
        @test haskey(result, :axes)
        @test haskey(result, :grid_layout)
        @test haskey(result, :data_mapping)
        @test isa(result.figure, Figure)
        @test isa(result.axes, Dict)
        @test isa(result.grid_layout, GridLayout)
        @test isa(result.data_mapping, Dict)
    end
    
    @testset "Data Processing and Grouping" begin
        result = geofacet(sample_data, :state, simple_plot_func)
        
        # Check that data was properly grouped and mapped
        @test length(result.data_mapping) == 5  # 5 states in sample data
        @test all(state in keys(result.data_mapping) for state in ["CA", "TX", "NY", "FL", "WA"])
        
        # Check that axes were created for data regions
        @test all(state in keys(result.axes) for state in ["CA", "TX", "NY", "FL", "WA"])
    end
    
    @testset "Grid Integration" begin
        # Test with default grid
        result1 = geofacet(sample_data, :state, simple_plot_func)
        @test !isnothing(result1.figure)
        
        # Test with custom grid
        custom_grid = load_us_state_grid(2)
        result2 = geofacet(sample_data, :state, simple_plot_func, grid=custom_grid)
        @test !isnothing(result2.figure)
        
        # Test with contiguous grid
        contiguous_grid = load_us_contiguous_grid()
        result3 = geofacet(sample_data, :state, simple_plot_func, grid=contiguous_grid)
        @test !isnothing(result3.figure)
    end
    
    @testset "Plot Function Execution" begin
        # Test that plot function is called for each region
        plot_calls = String[]
        tracking_plot_func = (ax, data) -> begin
            push!(plot_calls, data.state[1])  # Track which state was plotted
            scatter!(ax, [1], data.value)
        end
        
        result = geofacet(sample_data, :state, tracking_plot_func)
        @test length(plot_calls) == 5
        @test all(state in plot_calls for state in ["CA", "TX", "NY", "FL", "WA"])
    end
    
    @testset "Figure and Axis Configuration" begin
        # Test figure_kwargs
        result1 = geofacet(sample_data, :state, simple_plot_func, 
                          figure_kwargs=(size=(800, 600),))
        @test result1.figure.scene.viewport[].widths == (800, 600)
        
        # Test axis_kwargs
        result2 = geofacet(sample_data, :state, simple_plot_func,
                          axis_kwargs=(ylabel="Test Label",))
        # Check that at least one axis has the ylabel (implementation dependent)
        @test any(ax -> !isnothing(ax.ylabel[]), values(result2.axes))
    end
    
    @testset "Axis Linking" begin
        # Test no linking (default)
        result1 = geofacet(time_series_data, :state, line_plot_func, link_axes=:none)
        @test !isnothing(result1.figure)
        
        # Test x-axis linking
        result2 = geofacet(time_series_data, :state, line_plot_func, link_axes=:x)
        @test !isnothing(result2.figure)
        
        # Test y-axis linking
        result3 = geofacet(time_series_data, :state, line_plot_func, link_axes=:y)
        @test !isnothing(result3.figure)
        
        # Test both axes linking
        result4 = geofacet(time_series_data, :state, line_plot_func, link_axes=:both)
        @test !isnothing(result4.figure)
    end
    
    @testset "Missing Regions Handling" begin
        # Create data with only a few states
        limited_data = DataFrame(
            state = ["CA", "TX"],
            value = [100, 200]
        )
        
        # Test skip missing regions (default)
        result1 = geofacet(limited_data, :state, simple_plot_func, missing_regions=:skip)
        @test length(result1.data_mapping) == 2
        @test haskey(result1.data_mapping, "CA")
        @test haskey(result1.data_mapping, "TX")
        
        # Test empty axes for missing regions
        result2 = geofacet(limited_data, :state, simple_plot_func, missing_regions=:empty)
        @test length(result2.axes) >= 2  # Should have axes for grid positions
        
        # Test error on missing regions
        @test_throws Exception geofacet(limited_data, :state, simple_plot_func, missing_regions=:error)
    end
    
    @testset "Error Handling" begin
        # Test invalid column name
        @test_throws Exception geofacet(sample_data, :nonexistent_column, simple_plot_func)
        
        # Test empty data
        empty_data = DataFrame(state=String[], value=Int[])
        @test_throws Exception geofacet(empty_data, :state, simple_plot_func)
        
        # Test plot function that throws error
        error_plot_func = (ax, data) -> error("Test error in plot function")
        @test_throws Exception geofacet(sample_data, :state, error_plot_func)
    end
    
    @testset "Region Code Matching" begin
        # Test case insensitive matching
        mixed_case_data = DataFrame(
            state = ["ca", "TX", "ny"],  # Mixed case
            value = [100, 200, 150]
        )
        
        result = geofacet(mixed_case_data, :state, simple_plot_func)
        @test length(result.data_mapping) == 3
        
        # Test regions not in grid
        invalid_data = DataFrame(
            state = ["CA", "XX", "YY"],  # XX, YY not valid state codes
            value = [100, 200, 150]
        )
        
        # Should handle gracefully and only plot valid regions
        result = geofacet(invalid_data, :state, simple_plot_func)
        @test haskey(result.data_mapping, "CA")
        @test !haskey(result.data_mapping, "XX")
        @test !haskey(result.data_mapping, "YY")
    end
    
    @testset "Different Plot Types" begin
        # Test with different plot functions
        bar_plot_func = (ax, data) -> barplot!(ax, [1], data.value)
        result1 = geofacet(sample_data, :state, bar_plot_func)
        @test !isnothing(result1.figure)
        
        # Test with time series
        result2 = geofacet(time_series_data, :state, line_plot_func)
        @test !isnothing(result2.figure)
        
        # Test with multiple series
        multi_plot_func = (ax, data) -> begin
            lines!(ax, data.date, data.cases, color=:blue)
            scatter!(ax, data.date, data.cases, color=:red)
        end
        result3 = geofacet(time_series_data, :state, multi_plot_func)
        @test !isnothing(result3.figure)
    end
    
    @testset "Grid Layout Validation" begin
        result = geofacet(sample_data, :state, simple_plot_func)
        
        # Check that grid layout has appropriate structure
        @test !isnothing(result.grid_layout)
        
        # Check that axes are positioned correctly in the grid
        # (This will depend on the specific implementation)
        for (state, axis) in result.axes
            @test isa(axis, Axis)
        end
    end
    
    @testset "Performance and Memory" begin
        # Test with larger dataset
        large_data = DataFrame(
            state = repeat(["CA", "TX", "NY", "FL", "WA"], 100),
            value = rand(500),
            date = repeat([Date(2023, 1, 1)], 500)
        )
        
        # Should handle larger datasets without issues
        @test_nowarn geofacet(large_data, :state, simple_plot_func)
    end
    
    @testset "Integration with Existing Grid System" begin
        # Test that geofacet works with all available grids
        grids_to_test = [
            load_us_state_grid(1),
            load_us_state_grid(2),
            load_us_state_grid(3),
            load_us_state_grid_without_dc(1),
            load_us_contiguous_grid()
        ]
        
        for grid in grids_to_test
            result = geofacet(sample_data, :state, simple_plot_func, grid=grid)
            @test !isnothing(result.figure)
            @test !isnothing(result.grid_layout)
        end
    end
end