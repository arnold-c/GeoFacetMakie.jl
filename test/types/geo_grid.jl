"""
Tests for GeoGrid constructors, validation, and error handling
"""

using Test
using GeoFacetMakie

@testset "Position Conflicts" begin
    # No conflicts
    valid_entries = [GridEntry("A", 1, 1), GridEntry("B", 1, 2), GridEntry("C", 2, 1)]
    valid_grid = StructArrays.StructArray(valid_entries)
    @test validate_grid(valid_grid) == true

    # Position conflicts
    conflict_entries = [GridEntry("A", 1, 1), GridEntry("B", 1, 1)]
    conflict_grid = StructArrays.StructArray(conflict_entries)
    @test_throws ArgumentError validate_grid(conflict_grid)

    # Multiple conflicts
    multi_conflict_entries = [GridEntry("A", 1, 1), GridEntry("B", 1, 1), GridEntry("C", 2, 2), GridEntry("D", 2, 2)]
    multi_conflict = StructArrays.StructArray(multi_conflict_entries)
    @test_throws ArgumentError validate_grid(multi_conflict)
end

@testset "Invalid Positions" begin
    # Zero positions
    @test_throws ArgumentError StructArrays.StructArray([GridEntry("A", 0, 1)])
    @test_throws ArgumentError StructArrays.StructArray([GridEntry("A", 1, 0)])

    # Negative positions
    @test_throws ArgumentError StructArrays.StructArray([GridEntry("A", -1, 1)])
    @test_throws ArgumentError StructArrays.StructArray([GridEntry("A", 1, -1)])
end

@testset "Region Names" begin
    # Empty region names
    @test_throws ArgumentError StructArrays.StructArray([GridEntry("", 1, 1)])

    # Whitespace-only names
    @test_throws ArgumentError StructArrays.StructArray([GridEntry("   ", 1, 1)])

    # Valid names with spaces
    @test StructArrays.StructArray([GridEntry("New York", 1, 1)]) isa GeoGrid

    # Case sensitivity
    entries = [GridEntry("ca", 1, 1), GridEntry("CA", 1, 2)]
    grid = StructArrays.StructArray(entries)
    @test "ca" in grid.region
    @test "CA" in grid.region
end

@testset "Grid Completeness" begin
    # Complete rectangular grid
    complete_entries = [
        GridEntry("A", 1, 1), GridEntry("B", 1, 2),
        GridEntry("C", 2, 1), GridEntry("D", 2, 2),
    ]
    complete = StructArrays.StructArray(complete_entries)
    @test is_complete_rectangle(complete) == true

    # Incomplete grid (missing cells)
    incomplete_entries = [
        GridEntry("A", 1, 1), GridEntry("B", 1, 2),
        GridEntry("C", 2, 1),  # Missing (2, 2)
    ]
    incomplete = StructArrays.StructArray(incomplete_entries)
    @test is_complete_rectangle(incomplete) == false

    # Sparse grid
    sparse_entries = [GridEntry("A", 1, 1), GridEntry("B", 3, 3)]
    sparse = StructArrays.StructArray(sparse_entries)
    @test is_complete_rectangle(sparse) == false
end

