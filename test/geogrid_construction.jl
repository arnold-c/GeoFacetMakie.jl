"""
Tests for GeoGrid construction and basic field access
"""

@testset "GeoGrid Construction" begin
    # Basic construction
    @test GeoGrid("test_grid", Dict("CA" => (1, 1), "NY" => (1, 2))) isa GeoGrid
    
    # Empty grid
    @test GeoGrid("empty", Dict{String, Tuple{Int, Int}}()) isa GeoGrid
    
    # Single region
    @test GeoGrid("single", Dict("TX" => (1, 1))) isa GeoGrid
end

@testset "GeoGrid Field Access" begin
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