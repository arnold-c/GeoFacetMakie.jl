"""
Tests for GeoGrid edge cases and real-world scenarios
"""

using Test
using GeoFacetMakie

@testset "Edge Cases" begin
    # Very large grid
    large_entries = [GridEntry("R$(i)C$(j)", i, j) for i in 1:100, j in 1:100]
    large_grid = StructArrays.StructArray(large_entries)
    @test grid_dimensions(large_grid) == (100, 100)

    # Single row/column
    row_entries = [GridEntry("A", 1, 1), GridEntry("B", 1, 2), GridEntry("C", 1, 3)]
    row_grid = StructArrays.StructArray(row_entries)
    @test grid_dimensions(row_grid) == (1, 3)

    col_entries = [GridEntry("A", 1, 1), GridEntry("B", 2, 1), GridEntry("C", 3, 1)]
    col_grid = StructArrays.StructArray(col_entries)
    @test grid_dimensions(col_grid) == (3, 1)
end

@testset "Real-World Scenarios" begin
    # US states subset (common use case)
    us_entries = [
        GridEntry("CA", 3, 1), GridEntry("NV", 3, 2), GridEntry("AZ", 4, 2),
        GridEntry("OR", 2, 1), GridEntry("WA", 1, 1),
    ]
    us_subset = StructArrays.StructArray(us_entries)
    @test validate_grid(us_subset) == true
    @test grid_dimensions(us_subset) == (4, 2)

    # European countries
    europe_entries = [
        GridEntry("UK", 1, 1), GridEntry("FR", 2, 1), GridEntry("DE", 2, 2),
        GridEntry("ES", 3, 1), GridEntry("IT", 3, 2),
    ]
    europe = StructArrays.StructArray(europe_entries)
    @test validate_grid(europe) == true
end

