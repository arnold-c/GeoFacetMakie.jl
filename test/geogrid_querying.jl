"""
Tests for GeoGrid querying and utility functions
"""

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

@testset "Type Stability" begin
    grid = GeoGrid("test", Dict("CA" => (1, 1)))
    
    # Test that functions return expected types
    @test grid_dimensions(grid) isa Tuple{Int, Int}
    @test validate_grid(grid) isa Bool
    @test has_region(grid, "CA") isa Bool
    @test get_position(grid, "CA") isa Tuple{Int, Int}
    @test get_regions(grid) isa Vector{String}
end