"""
Tests for legend detection functions in plotting functionality
"""

using Test
using Makie
using GeoFacetMakie

@testset "Legend Detection Functions" begin
    
    @testset "_has_labeled_plots" begin
        # Test figure with no plots
        empty_fig = Figure()
        @test GeoFacetMakie._has_labeled_plots(empty_fig) == false
        
        # Test figure with unlabeled plots
        fig_unlabeled = Figure()
        ax_unlabeled = Axis(fig_unlabeled[1, 1])
        lines!(ax_unlabeled, [1, 2, 3], [1, 4, 2])  # No label
        scatter!(ax_unlabeled, [1, 2, 3], [2, 3, 1])  # No label
        
        @test GeoFacetMakie._has_labeled_plots(fig_unlabeled) == false
        
        # Test figure with labeled plots
        fig_labeled = Figure()
        ax_labeled = Axis(fig_labeled[1, 1])
        lines!(ax_labeled, [1, 2, 3], [1, 4, 2], label = "Line Plot")
        scatter!(ax_labeled, [1, 2, 3], [2, 3, 1])  # Still no label on this one
        
        @test GeoFacetMakie._has_labeled_plots(fig_labeled) == true
        
        # Test figure with empty label (should be treated as no label)
        fig_empty_label = Figure()
        ax_empty_label = Axis(fig_empty_label[1, 1])
        lines!(ax_empty_label, [1, 2, 3], [1, 4, 2], label = "")
        
        @test GeoFacetMakie._has_labeled_plots(fig_empty_label) == false
        
        # Test figure with multiple axes, some with labels
        fig_multi = Figure()
        ax1_multi = Axis(fig_multi[1, 1])
        ax2_multi = Axis(fig_multi[1, 2])
        
        lines!(ax1_multi, [1, 2, 3], [1, 4, 2])  # No label
        lines!(ax2_multi, [1, 2, 3], [2, 3, 1], label = "Labeled Line")
        
        @test GeoFacetMakie._has_labeled_plots(fig_multi) == true
        
        # Test figure with multiple labeled plots
        fig_multi_labeled = Figure()
        ax_multi_labeled = Axis(fig_multi_labeled[1, 1])
        lines!(ax_multi_labeled, [1, 2, 3], [1, 4, 2], label = "First Line")
        scatter!(ax_multi_labeled, [1, 2, 3], [2, 3, 1], label = "Scatter Points")
        
        @test GeoFacetMakie._has_labeled_plots(fig_multi_labeled) == true
        
        # Test with different plot types
        fig_various = Figure()
        ax_various = Axis(fig_various[1, 1])
        barplot!(ax_various, [1, 2, 3], [1, 4, 2], label = "Bars")
        
        @test GeoFacetMakie._has_labeled_plots(fig_various) == true
        
        # Test edge case: figure with axis but no plots
        fig_no_plots = Figure()
        ax_no_plots = Axis(fig_no_plots[1, 1])
        
        @test GeoFacetMakie._has_labeled_plots(fig_no_plots) == false
    end
end