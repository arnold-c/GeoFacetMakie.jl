"""
Tests for grid loading functionality
"""

using Test
using GeoFacetMakie

@testset "Grid Loading Tests" begin

    @testset "load_us_state_grid" begin
        @testset "Valid versions" begin
            for version in 1:3
                grid = load_us_state_grid(version)
                @test isa(grid, GeoGrid)
                @test grid.name == "us_state_grid$(version)"

                # Should have 50 states + DC = 51 regions
                @test length(grid.positions) == 51

                # Check that DC is included
                @test haskey(grid.positions, "DC")

                # Check some known states
                @test haskey(grid.positions, "CA")
                @test haskey(grid.positions, "TX")
                @test haskey(grid.positions, "NY")
            end
        end

        @testset "Invalid versions" begin
            @test_throws ArgumentError load_us_state_grid(0)
            @test_throws ArgumentError load_us_state_grid(4)
            @test_throws ArgumentError load_us_state_grid(-1)
        end

        @testset "Default version" begin
            grid_default = load_us_state_grid()
            grid_v1 = load_us_state_grid(1)
            @test grid_default.positions == grid_v1.positions
        end
    end

    @testset "load_us_state_grid_without_dc" begin
        @testset "Valid versions" begin
            for version in 1:3
                grid = load_us_state_grid_without_dc(version)
                @test isa(grid, GeoGrid)
                @test grid.name == "us_state_without_DC_grid$(version)"

                # Should have 50 states (no DC)
                @test length(grid.positions) == 50

                # Check that DC is NOT included
                @test !haskey(grid.positions, "DC")

                # Check some known states are still there
                @test haskey(grid.positions, "CA")
                @test haskey(grid.positions, "TX")
                @test haskey(grid.positions, "NY")
            end
        end

        @testset "Invalid versions" begin
            @test_throws ArgumentError load_us_state_grid_without_dc(0)
            @test_throws ArgumentError load_us_state_grid_without_dc(4)
        end
    end

    @testset "load_us_contiguous_grid" begin
        grid = load_us_contiguous_grid()
        @test isa(grid, GeoGrid)
        @test grid.name == "us_state_contiguous_grid1"

        # Should have 48 contiguous states + DC = 49 regions
        @test length(grid.positions) == 49

        # Should include DC
        @test haskey(grid.positions, "DC")

        # Should NOT include Alaska and Hawaii
        @test !haskey(grid.positions, "AK")
        @test !haskey(grid.positions, "HI")

        # Should include contiguous states
        @test haskey(grid.positions, "CA")
        @test haskey(grid.positions, "TX")
        @test haskey(grid.positions, "FL")
        @test haskey(grid.positions, "ME")
    end

    @testset "list_available_grids" begin
        grids = list_available_grids()
        @test isa(grids, Vector{String})
        @test length(grids) >= 7  # We downloaded 7 grids

        # Check that our downloaded grids are listed
        expected_grids = [
            "us_state_grid1",
            "us_state_grid2",
            "us_state_grid3",
            "us_state_without_DC_grid1",
            "us_state_without_DC_grid2",
            "us_state_without_DC_grid3",
            "us_state_contiguous_grid1",
        ]

        for expected_grid in expected_grids
            @test expected_grid ∈ grids
        end
    end

    @testset "load_grid" begin
        @testset "Valid grid names" begin
            grid = load_grid("us_state_grid1")
            @test isa(grid, GeoGrid)
            @test grid.name == "us_state_grid1"
            @test length(grid.positions) == 51  # 50 states + DC
        end

        @testset "Invalid grid names" begin
            @test_throws ArgumentError load_grid("nonexistent_grid")
        end
    end

    @testset "Grid validation" begin
        @testset "All grids have valid structure" begin
            available_grids = list_available_grids()

            for grid_name in available_grids
                grid = load_grid(grid_name)

                # Basic structure tests
                @test isa(grid, GeoGrid)
                @test !isempty(grid.positions)

                # All regions should have valid positions
                for (code, (row, col)) in grid.positions
                    @test isa(row, Int)
                    @test isa(col, Int)
                    @test row > 0
                    @test col > 0
                end

                # Grid should be valid (no overlapping positions)
                @test validate_grid(grid)
            end
        end
    end

    @testset "us_state_grid constant" begin
        @test isa(us_state_grid, GeoGrid)
        @test us_state_grid.name == "us_state_grid1"
        @test length(us_state_grid.positions) == 51  # 50 states + DC

        # Check some known states
        @test haskey(us_state_grid.positions, "CA")
        @test haskey(us_state_grid.positions, "TX")
        @test haskey(us_state_grid.positions, "DC")
    end

end

