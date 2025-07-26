"""
Tests for GeoGrid validation and error handling
"""

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