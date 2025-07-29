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

                # Should have 50 states + DC = 51 regions
                @test length(grid) == 51

                # Check that DC is included
                @test "DC" in grid.region

                # Check some known states
                @test "CA" in grid.region
                @test "TX" in grid.region
                @test "NY" in grid.region
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
            @test grid_default.region == grid_v1.region
            @test grid_default.row == grid_v1.row
            @test grid_default.col == grid_v1.col
        end
    end

    @testset "load_us_state_grid_without_dc" begin
        @testset "Valid versions" begin
            for version in 1:3
                grid = load_us_state_grid_without_dc(version)
                @test isa(grid, GeoGrid)

                # Should have 50 states (no DC)
                @test length(grid) == 50

                # Check that DC is NOT included
                @test !("DC" in grid.region)

                # Check some known states are still there
                @test "CA" in grid.region
                @test "TX" in grid.region
                @test "NY" in grid.region
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

        # Should have 48 contiguous states + DC = 49 regions
        @test length(grid) == 49

        # Should include DC
        @test "DC" in grid.region

        # Should NOT include Alaska and Hawaii
        @test !("AK" in grid.region)
        @test !("HI" in grid.region)

        # Should include contiguous states
        @test "CA" in grid.region
        @test "TX" in grid.region
        @test "FL" in grid.region
        @test "ME" in grid.region
    end

    @testset "list_available_grids" begin
        grids = list_available_grids()
        @test isa(grids, Vector{String})
        @test length(grids) >= 9  # We have 9 grid files

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
            @test length(grid) == 51  # 50 states + DC
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
                @test !isempty(grid)

                # All regions should have valid positions
                for (code, row, col) in grid
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
        @test length(us_state_grid) == 51  # 50 states + DC

        # Check some known states
        @test "CA" in us_state_grid.region
        @test "TX" in us_state_grid.region
        @test "DC" in us_state_grid.region
    end

end
