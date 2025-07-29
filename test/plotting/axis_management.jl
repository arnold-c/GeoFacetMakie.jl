"""
Tests for axis management functions in plotting functionality
"""

using Test
using Makie
using GeoFacetMakie

@testset "Axis Management Functions" begin
    
    @testset "_get_yaxis_position" begin
        # Test default position (left)
        default_kwargs = NamedTuple()
        @test GeoFacetMakie._get_yaxis_position(default_kwargs) == :left
        
        # Test explicit left position
        left_kwargs = (yaxisposition = :left,)
        @test GeoFacetMakie._get_yaxis_position(left_kwargs) == :left
        
        # Test right position
        right_kwargs = (yaxisposition = :right,)
        @test GeoFacetMakie._get_yaxis_position(right_kwargs) == :right
        
        # Test with other kwargs present
        mixed_kwargs = (xlabel = "X Label", yaxisposition = :right, ylabel = "Y Label")
        @test GeoFacetMakie._get_yaxis_position(mixed_kwargs) == :right
    end
    
    @testset "_merge_axis_kwargs" begin
        # Test basic merging with single axis
        common = (xlabel = "Common X", titlesize = 12)
        per_axis = [(ylabel = "Y1", color = :blue)]
        decoration = [(xticksvisible = false,)]
        
        result = GeoFacetMakie._merge_axis_kwargs(common, per_axis, decoration, 1)
        
        @test length(result) == 1
        @test result[1].xlabel == "Common X"
        @test result[1].titlesize == 12
        @test result[1].ylabel == "Y1"
        @test result[1].color == :blue
        @test result[1].xticksvisible == false
        
        # Test priority: decoration > per_axis > common
        common2 = (color = :red, xlabel = "Common")
        per_axis2 = [(color = :blue, ylabel = "Per Axis")]
        decoration2 = [(color = :green,)]
        
        result2 = GeoFacetMakie._merge_axis_kwargs(common2, per_axis2, decoration2, 1)
        @test result2[1].color == :green  # decoration wins
        @test result2[1].xlabel == "Common"  # from common
        @test result2[1].ylabel == "Per Axis"  # from per_axis
        
        # Test multiple axes
        common3 = (titlesize = 10,)
        per_axis3 = [(ylabel = "Y1",), (ylabel = "Y2", yscale = log10)]
        decoration3 = [(xticksvisible = false,), (yticksvisible = false,)]
        
        result3 = GeoFacetMakie._merge_axis_kwargs(common3, per_axis3, decoration3, 2)
        @test length(result3) == 2
        @test result3[1].titlesize == 10
        @test result3[1].ylabel == "Y1"
        @test result3[1].xticksvisible == false
        @test result3[2].titlesize == 10
        @test result3[2].ylabel == "Y2"
        @test result3[2].yscale == log10
        @test result3[2].yticksvisible == false
        
        # Test when per_axis is shorter than num_axes
        result4 = GeoFacetMakie._merge_axis_kwargs(common3, per_axis3, decoration3, 3)
        @test length(result4) == 3
        @test result4[3].titlesize == 10  # common applied
        @test !haskey(result4[3], :ylabel)  # no per_axis for index 3
        @test !haskey(result4[3], :xticksvisible)  # no decoration for index 3
        
        # Test default behavior when num_axes = 0 and no per_axis
        result5 = GeoFacetMakie._merge_axis_kwargs(common, NamedTuple[], NamedTuple[], 0)
        @test length(result5) == 1  # defaults to 1
        
        # Test when num_axes = 0 but per_axis provided
        result6 = GeoFacetMakie._merge_axis_kwargs(common, per_axis, decoration, 0)
        @test length(result6) == 1  # uses length of per_axis
    end
    
    @testset "Axis Collection Functions" begin
        # Create a simple figure with axes for testing
        fig = Figure()
        
        # Create nested GridLayouts with axes
        gl1 = GridLayout(fig[1, 1])
        gl2 = GridLayout(fig[1, 2])
        
        ax1 = Axis(gl1[1, 1])
        ax2 = Axis(gl1[2, 1])
        ax3 = Axis(gl2[1, 1])
        
        layouts = [gl1, gl2]
        
        @testset "collect_gl_axes" begin
            axes = GeoFacetMakie.collect_gl_axes(layouts)
            @test axes isa Vector{Axis}
            @test length(axes) == 3
            @test ax1 in axes
            @test ax2 in axes
            @test ax3 in axes
        end
        
        @testset "collect_gl_axes_by_position" begin
            axes_by_pos = GeoFacetMakie.collect_gl_axes_by_position(layouts)
            @test axes_by_pos isa Vector{Vector{Axis}}
            @test length(axes_by_pos) >= 1
            
            # First position should have axes from both layouts
            @test length(axes_by_pos[1]) == 2  # ax1 from gl1, ax3 from gl2
            @test ax1 in axes_by_pos[1]
            @test ax3 in axes_by_pos[1]
            
            # Second position should have only ax2 from gl1
            if length(axes_by_pos) >= 2
                @test length(axes_by_pos[2]) == 1
                @test ax2 in axes_by_pos[2]
            end
        end
        
        @testset "_collect_axes_ordered" begin
            axes_gl1 = GeoFacetMakie._collect_axes_ordered(gl1)
            @test axes_gl1 isa Vector{Axis}
            @test length(axes_gl1) == 2
            @test ax1 in axes_gl1
            @test ax2 in axes_gl1
            
            axes_gl2 = GeoFacetMakie._collect_axes_ordered(gl2)
            @test axes_gl2 isa Vector{Axis}
            @test length(axes_gl2) == 1
            @test ax3 in axes_gl2
        end
        
        @testset "hide_all_decorations!" begin
            # Create a fresh layout for this test
            test_fig = Figure()
            test_gl = GridLayout(test_fig[1, 1])
            test_ax = Axis(test_gl[1, 1])
            
            # Initially, decorations should be visible
            @test test_ax.xticksvisible[] == true
            @test test_ax.yticksvisible[] == true
            
            # Hide decorations
            GeoFacetMakie.hide_all_decorations!(test_gl)
            
            # Check that decorations are hidden
            @test test_ax.xticksvisible[] == false
            @test test_ax.yticksvisible[] == false
            @test test_ax.xlabelvisible[] == false
            @test test_ax.ylabelvisible[] == false
        end
    end
    
    @testset "Edge Cases" begin
        # Test with empty layouts
        empty_axes = GeoFacetMakie.collect_gl_axes(GridLayout[])
        @test isempty(empty_axes)
        
        empty_by_pos = GeoFacetMakie.collect_gl_axes_by_position(GridLayout[])
        @test isempty(empty_by_pos)
        
        # Test with layout containing no axes
        fig = Figure()
        empty_gl = GridLayout(fig[1, 1])
        
        no_axes = GeoFacetMakie.collect_gl_axes([empty_gl])
        @test isempty(no_axes)
        
        ordered_empty = GeoFacetMakie._collect_axes_ordered(empty_gl)
        @test isempty(ordered_empty)
    end
end