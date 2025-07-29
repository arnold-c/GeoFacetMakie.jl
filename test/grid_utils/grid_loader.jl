"""
Tests for grid loading functionality
"""

using Test
using GeoFacetMakie

@testset "Grid Loading Tests" begin

    @testset "load_grid_from_csv with two parameters" begin
        @testset "Valid directory and filename" begin
            grids_dir = joinpath(@__DIR__, "..", "..", "src", "data", "grids")

            # Test with .csv extension
            grid1 = load_grid_from_csv("us_state_grid1.csv", grids_dir)
            @test isa(grid1, GeoGrid)
            @test length(grid1) == 51  # 50 states + DC

            # Test without .csv extension
            grid2 = load_grid_from_csv("us_state_grid1", grids_dir)
            @test isa(grid2, GeoGrid)
            @test length(grid2) == 51

            # Should be identical
            @test grid1.region == grid2.region
            @test grid1.row == grid2.row
            @test grid1.col == grid2.col
        end

        @testset "Invalid files" begin
            grids_dir = joinpath(@__DIR__, "..", "..", "src", "data", "grids")
            @test_throws ArgumentError load_grid_from_csv("nonexistent.csv", grids_dir)
            @test_throws ArgumentError load_grid_from_csv("us_state_grid1.csv", "/nonexistent/dir")
        end
    end

    @testset "load_grid_from_csv with one parameter" begin
        @testset "Valid filenames" begin
            # Test with .csv extension
            grid1 = load_grid_from_csv("us_state_grid1.csv")
            @test isa(grid1, GeoGrid)
            @test length(grid1) == 51

            # Test without .csv extension
            grid2 = load_grid_from_csv("us_state_grid1")
            @test isa(grid2, GeoGrid)
            @test length(grid2) == 51

            # Should be identical
            @test grid1.region == grid2.region
        end

        @testset "Invalid filenames" begin
            @test_throws ArgumentError load_grid_from_csv("nonexistent_grid")
        end
    end

    @testset "US state grids" begin
        @testset "us_state_grid variants" begin
            for version in 1:3
                grid_name = "us_state_grid$version"
                grid = load_grid(grid_name)
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

        @testset "us_state_without_DC_grid variants" begin
            for version in 1:3
                grid_name = "us_state_without_DC_grid$version"
                grid = load_grid(grid_name)
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

        @testset "us_state_contiguous_grid" begin
            grid = load_grid("us_state_contiguous_grid1")
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
    end

    @testset "list_available_grids" begin
        grids = list_available_grids()
        @test isa(grids, Vector{String})
        @test length(grids) >= 200  # We have 218 grid files

        # Check that some key grids are listed
        expected_grids = [
            "us_state_grid1",
            "us_state_grid2",
            "us_state_grid3",
            "us_state_without_DC_grid1",
            "us_state_contiguous_grid1",
            "eu_grid1",
            "india_grid1",
            "world_countries_grid1",
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
        @testset "Sample grids have valid structure" begin
            # Test a representative sample of grids instead of all 218
            sample_grids = [
                "us_state_grid1",
                "us_state_without_DC_grid1",
                "us_state_contiguous_grid1",
                "eu_grid1",
                "india_grid1",
                "world_countries_grid1",
                "africa_countries_grid1",
                "br_states_grid1",
            ]

            for grid_name in sample_grids
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
