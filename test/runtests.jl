using GeoFacetMakie
using Test
using DataFrames
using Makie

@testset "GeoFacetMakie.jl" begin
    @testset "Package Loading" begin
        @test isa(GeoFacetMakie, Module)
        @test isdefined(GeoFacetMakie, :Makie)
        @test isdefined(GeoFacetMakie, :DataFrames)
    end

    @testset "GeoGrid Tests" begin
        @testset "Construction" begin
            # Basic construction
            @test GeoGrid("test_grid", Dict("CA" => (1, 1), "NY" => (1, 2))) isa GeoGrid

            # Empty grid
            @test GeoGrid("empty", Dict{String, Tuple{Int, Int}}()) isa GeoGrid

            # Single region
            @test GeoGrid("single", Dict("TX" => (1, 1))) isa GeoGrid
        end

        @testset "Field Access" begin
            grid = GeoGrid("test", Dict("CA" => (1, 1), "NY" => (1, 2)))

            @test grid.name == "test"
            @test grid.positions["CA"] == (1, 1)
            @test grid.positions["NY"] == (1, 2)
            @test length(grid.positions) == 2
        end

        @testset "Grid Dimensions" begin
            grid = GeoGrid("test", Dict("A" => (1, 1), "B" => (2, 3), "C" => (1, 2)))

            @test grid_dimensions(grid) == (2, 3)  # max_row, max_col

            # Single cell
            single = GeoGrid("single", Dict("A" => (1, 1)))
            @test grid_dimensions(single) == (1, 1)

            # Empty grid
            empty_grid = GeoGrid("empty", Dict{String, Tuple{Int, Int}}())
            @test grid_dimensions(empty_grid) == (0, 0)
        end

        @testset "Position Conflicts" begin
            # No conflicts
            valid_grid = GeoGrid("valid", Dict("A" => (1, 1), "B" => (1, 2), "C" => (2, 1)))
            @test validate_grid(valid_grid) == true

            # Position conflicts
            conflict_grid = GeoGrid("conflict", Dict("A" => (1, 1), "B" => (1, 1)))
            @test_throws ArgumentError validate_grid(conflict_grid)

            # Multiple conflicts
            multi_conflict = GeoGrid("multi", Dict("A" => (1, 1), "B" => (1, 1), "C" => (2, 2), "D" => (2, 2)))
            @test_throws ArgumentError validate_grid(multi_conflict)
        end

        @testset "Invalid Positions" begin
            # Zero positions
            @test_throws ArgumentError GeoGrid("zero", Dict("A" => (0, 1)))
            @test_throws ArgumentError GeoGrid("zero", Dict("A" => (1, 0)))

            # Negative positions
            @test_throws ArgumentError GeoGrid("neg", Dict("A" => (-1, 1)))
            @test_throws ArgumentError GeoGrid("neg", Dict("A" => (1, -1)))
        end

        @testset "Region Names" begin
            # Empty region names
            @test_throws ArgumentError GeoGrid("empty_name", Dict("" => (1, 1)))

            # Whitespace-only names
            @test_throws ArgumentError GeoGrid("whitespace", Dict("   " => (1, 1)))

            # Valid names with spaces
            @test GeoGrid("spaces", Dict("New York" => (1, 1))) isa GeoGrid

            # Case sensitivity
            grid = GeoGrid("case", Dict("ca" => (1, 1), "CA" => (1, 2)))
            @test haskey(grid.positions, "ca")
            @test haskey(grid.positions, "CA")
        end

        @testset "Grid Querying" begin
            grid = GeoGrid("test", Dict("CA" => (1, 1), "NY" => (1, 2), "TX" => (2, 1)))

            # Check if region exists
            @test has_region(grid, "CA") == true
            @test has_region(grid, "FL") == false

            # Get position
            @test get_position(grid, "CA") == (1, 1)
            @test get_position(grid, "nonexistent") === nothing

            # Get region at position
            @test get_region_at(grid, 1, 1) == "CA"
            @test get_region_at(grid, 3, 3) === nothing

            # List all regions
            regions = get_regions(grid)
            @test "CA" in regions
            @test "NY" in regions
            @test "TX" in regions
            @test length(regions) == 3
        end

        @testset "Grid Completeness" begin
            # Complete rectangular grid
            complete = GeoGrid("complete", Dict(
                "A" => (1, 1), "B" => (1, 2),
                "C" => (2, 1), "D" => (2, 2)
            ))
            @test is_complete_rectangle(complete) == true

            # Incomplete grid (missing cells)
            incomplete = GeoGrid("incomplete", Dict(
                "A" => (1, 1), "B" => (1, 2),
                "C" => (2, 1)  # Missing (2, 2)
            ))
            @test is_complete_rectangle(incomplete) == false

            # Sparse grid
            sparse = GeoGrid("sparse", Dict("A" => (1, 1), "B" => (3, 3)))
            @test is_complete_rectangle(sparse) == false
        end

        @testset "Edge Cases" begin
            # Very large grid
            large_positions = Dict("R$(i)C$(j)" => (i, j) for i in 1:100, j in 1:100)
            large_grid = GeoGrid("large", large_positions)
            @test grid_dimensions(large_grid) == (100, 100)

            # Single row/column
            row_grid = GeoGrid("row", Dict("A" => (1, 1), "B" => (1, 2), "C" => (1, 3)))
            @test grid_dimensions(row_grid) == (1, 3)

            col_grid = GeoGrid("col", Dict("A" => (1, 1), "B" => (2, 1), "C" => (3, 1)))
            @test grid_dimensions(col_grid) == (3, 1)
        end

        @testset "Type Stability" begin
            grid = GeoGrid("test", Dict("CA" => (1, 1)))

            # Test that functions return expected types
            @test grid_dimensions(grid) isa Tuple{Int, Int}
            @test validate_grid(grid) isa Bool
            @test has_region(grid, "CA") isa Bool
            @test get_position(grid, "CA") isa Tuple{Int, Int}
            @test get_regions(grid) isa Vector{String}
        end

        @testset "Real-World Scenarios" begin
            # US states subset (common use case)
            us_subset = GeoGrid("us_subset", Dict(
                "CA" => (3, 1), "NV" => (3, 2), "AZ" => (4, 2),
                "OR" => (2, 1), "WA" => (1, 1)
            ))
            @test validate_grid(us_subset) == true
            @test grid_dimensions(us_subset) == (4, 2)

            # European countries
            europe = GeoGrid("europe", Dict(
                "UK" => (1, 1), "FR" => (2, 1), "DE" => (2, 2),
                "ES" => (3, 1), "IT" => (3, 2)
            ))
            @test validate_grid(europe) == true
        end
    end
end

using JET
@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(GeoFacetMakie, target_modules=(GeoFacetMakie,))))
end

@testset "QA with Aqua" begin
    import Aqua
    Aqua.test_all(GeoFacetMakie)
end


