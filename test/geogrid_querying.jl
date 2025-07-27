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

@testset "Neighbor Detection" begin
    # Create a 3x3 grid with some missing cells
    #   A B C
    #   D   F
    #   G H I
    grid = GeoGrid(
        "test", Dict(
            "A" => (1, 1), "B" => (1, 2), "C" => (1, 3),
            "D" => (2, 1), "F" => (2, 3),
            "G" => (3, 1), "H" => (3, 2), "I" => (3, 3)
        )
    )

    # Test has_neighbor_below
    @test has_neighbor_below(grid, "A") == true   # A has D below
    @test has_neighbor_below(grid, "B") == false  # B has empty cell below
    @test has_neighbor_below(grid, "C") == true   # C has F below
    @test has_neighbor_below(grid, "D") == true   # D has G below
    @test has_neighbor_below(grid, "G") == false  # G is at bottom
    @test has_neighbor_below(grid, "nonexistent") == false

    # Test has_neighbor_left
    @test has_neighbor_left(grid, "A") == false  # A is at left edge
    @test has_neighbor_left(grid, "B") == true   # B has A to left
    @test has_neighbor_left(grid, "C") == true   # C has B to left
    @test has_neighbor_left(grid, "F") == false  # F has empty cell to left
    @test has_neighbor_left(grid, "H") == true   # H has G to left
    @test has_neighbor_left(grid, "nonexistent") == false

    # Test has_neighbor_right
    @test has_neighbor_right(grid, "A") == true   # A has B to right
    @test has_neighbor_right(grid, "B") == true   # B has C to right
    @test has_neighbor_right(grid, "C") == false  # C is at right edge
    @test has_neighbor_right(grid, "D") == false  # D has empty cell to right
    @test has_neighbor_right(grid, "G") == true   # G has H to right
    @test has_neighbor_right(grid, "nonexistent") == false

    # Test has_neighbor_above
    @test has_neighbor_above(grid, "A") == false  # A is at top
    @test has_neighbor_above(grid, "D") == true   # D has A above
    @test has_neighbor_above(grid, "F") == true   # F has C above
    @test has_neighbor_above(grid, "G") == true   # G has D above
    @test has_neighbor_above(grid, "H") == false  # H has empty cell above
    @test has_neighbor_above(grid, "nonexistent") == false
end

@testset "Type Stability" begin
    grid = GeoGrid("test", Dict("CA" => (1, 1)))

    # Test that functions return expected types
    @test grid_dimensions(grid) isa Tuple{Int, Int}
    @test validate_grid(grid) isa Bool
    @test has_region(grid, "CA") isa Bool
    @test get_position(grid, "CA") isa Tuple{Int, Int}
    @test get_regions(grid) isa Vector{String}

    # Test neighbor detection function types
    @test has_neighbor_below(grid, "CA") isa Bool
    @test has_neighbor_left(grid, "CA") isa Bool
    @test has_neighbor_right(grid, "CA") isa Bool
    @test has_neighbor_above(grid, "CA") isa Bool
end

