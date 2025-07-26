"""
Tests for GeoGrid edge cases and real-world scenarios
"""

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