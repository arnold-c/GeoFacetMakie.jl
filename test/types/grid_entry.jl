"""
Tests for GridEntry struct construction, iteration, and basic functionality
"""

using Test
using GeoFacetMakie

@testset "GeoGrid Construction" begin
    # Basic construction
    entries = [GridEntry("CA", 1, 1), GridEntry("NY", 1, 2)]
    grid = StructArrays.StructArray(entries)
    @test grid isa GeoGrid

    # Empty grid
    empty_grid = StructArrays.StructArray(GridEntry[])
    @test empty_grid isa GeoGrid

    # Single region
    single_grid = StructArrays.StructArray([GridEntry("TX", 1, 1)])
    @test single_grid isa GeoGrid
end

@testset "GeoGrid Field Access" begin
    entries = [GridEntry("CA", 1, 1), GridEntry("NY", 1, 2)]
    grid = StructArrays.StructArray(entries)

    @test "CA" in grid.region
    @test "NY" in grid.region
    @test length(grid) == 2

    # Test accessing specific positions
    ca_idx = findfirst(==(("CA")), grid.region)
    ny_idx = findfirst(==(("NY")), grid.region)
    @test grid.row[ca_idx] == 1 && grid.col[ca_idx] == 1
    @test grid.row[ny_idx] == 1 && grid.col[ny_idx] == 2
end

@testset "GridEntry Iteration and Unpacking" begin
    entry = GridEntry("CA", 2, 3)

    # Test that GridEntry is iterable
    @test length(entry) == 3

    # Test unpacking
    region, row, col = entry
    @test region == "CA"
    @test row == 2
    @test col == 3

    # Test collect
    values = collect(entry)
    @test values == ["CA", 2, 3]

    # Test iteration in loop
    collected = []
    for value in entry
        push!(collected, value)
    end
    @test collected == ["CA", 2, 3]

    # Test indexing
    @test entry[1] == "CA"
    @test entry[2] == 2
    @test entry[3] == 3
    @test_throws BoundsError entry[4]
    @test_throws BoundsError entry[0]
end

@testset "Grid Dimensions" begin
    entries = [GridEntry("A", 1, 1), GridEntry("B", 2, 3), GridEntry("C", 1, 2)]
    grid = StructArrays.StructArray(entries)

    @test grid_dimensions(grid) == (2, 3)  # max_row, max_col

    # Single cell
    single = StructArrays.StructArray([GridEntry("A", 1, 1)])
    @test grid_dimensions(single) == (1, 1)

    # Empty grid
    empty_grid = StructArrays.StructArray(GridEntry[])
    @test grid_dimensions(empty_grid) == (0, 0)
end

