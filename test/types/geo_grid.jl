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

@testset "GeoGrid Constructor - Dict{String, Tuple{Int, Int}}" begin
    # Basic construction
    positions = Dict("CA" => (1, 1), "NY" => (1, 2), "TX" => (2, 1))
    grid = GeoGrid("test_grid", positions)
    
    @test grid isa GeoGrid
    @test length(grid) == 3
    @test "CA" in grid.region
    @test "NY" in grid.region
    @test "TX" in grid.region
    
    # Check positions are correct
    ca_idx = findfirst(==(("CA")), grid.region)
    ny_idx = findfirst(==(("NY")), grid.region)
    tx_idx = findfirst(==(("TX")), grid.region)
    
    @test grid.row[ca_idx] == 1 && grid.col[ca_idx] == 1
    @test grid.row[ny_idx] == 1 && grid.col[ny_idx] == 2
    @test grid.row[tx_idx] == 2 && grid.col[tx_idx] == 1
    
    # Names should default to regions
    @test grid.name[ca_idx] == "CA"
    @test grid.name[ny_idx] == "NY"
    @test grid.name[tx_idx] == "TX"
    
    # Metadata should be empty
    @test isempty(grid.metadata[ca_idx])
    @test isempty(grid.metadata[ny_idx])
    @test isempty(grid.metadata[tx_idx])
    
    # Empty positions dict
    empty_grid = GeoGrid("empty", Dict{String, Tuple{Int, Int}}())
    @test empty_grid isa GeoGrid
    @test length(empty_grid) == 0
    
    # Single position
    single_grid = GeoGrid("single", Dict("A" => (1, 1)))
    @test single_grid isa GeoGrid
    @test length(single_grid) == 1
    @test single_grid.region[1] == "A"
    
    # Error cases
    @test_throws ArgumentError GeoGrid("test", Dict("" => (1, 1)))  # Empty region name
    @test_throws ArgumentError GeoGrid("test", Dict("   " => (1, 1)))  # Whitespace-only name
    @test_throws ArgumentError GeoGrid("test", Dict("A" => (0, 1)))  # Zero row
    @test_throws ArgumentError GeoGrid("test", Dict("A" => (1, 0)))  # Zero col
    @test_throws ArgumentError GeoGrid("test", Dict("A" => (-1, 1)))  # Negative row
    @test_throws ArgumentError GeoGrid("test", Dict("A" => (1, -1)))  # Negative col
    
    # Position conflicts
    @test_throws ArgumentError GeoGrid("test", Dict("A" => (1, 1), "B" => (1, 1)))
end

@testset "GeoGrid Constructor - Vectors (3 args)" begin
    # Basic construction
    regions = ["CA", "NY", "TX"]
    rows = [1, 1, 2]
    cols = [1, 2, 1]
    
    grid = GeoGrid(regions, rows, cols)
    
    @test grid isa GeoGrid
    @test length(grid) == 3
    @test grid.region == regions
    @test grid.row == rows
    @test grid.col == cols
    @test grid.name == regions  # Names should default to regions
    @test all(isempty(meta) for meta in grid.metadata)  # Metadata should be empty
    
    # Single element
    single_grid = GeoGrid(["A"], [1], [1])
    @test single_grid isa GeoGrid
    @test length(single_grid) == 1
    @test single_grid.region[1] == "A"
    @test single_grid.name[1] == "A"
    
    # Empty vectors
    empty_grid = GeoGrid(String[], Int[], Int[])
    @test empty_grid isa GeoGrid
    @test length(empty_grid) == 0
    
    # Error cases - mismatched lengths
    @test_throws ArgumentError GeoGrid(["A", "B"], [1], [1])  # regions longer
    @test_throws ArgumentError GeoGrid(["A"], [1, 2], [1])  # rows longer
    @test_throws ArgumentError GeoGrid(["A"], [1], [1, 2])  # cols longer
    @test_throws ArgumentError GeoGrid(["A", "B"], [1, 2], [1])  # cols shorter
    
    # Error cases - invalid values
    @test_throws ArgumentError GeoGrid([""], [1], [1])  # Empty region name
    @test_throws ArgumentError GeoGrid(["   "], [1], [1])  # Whitespace-only name
    @test_throws ArgumentError GeoGrid(["A"], [0], [1])  # Zero row
    @test_throws ArgumentError GeoGrid(["A"], [1], [0])  # Zero col
    @test_throws ArgumentError GeoGrid(["A"], [-1], [1])  # Negative row
    @test_throws ArgumentError GeoGrid(["A"], [1], [-1])  # Negative col
end

@testset "GeoGrid Constructor - Vectors (4 args)" begin
    # Basic construction with names
    regions = ["CA", "NY", "TX"]
    rows = [1, 1, 2]
    cols = [1, 2, 1]
    names = ["California", "New York", "Texas"]
    
    grid = GeoGrid(regions, rows, cols, names)
    
    @test grid isa GeoGrid
    @test length(grid) == 3
    @test grid.region == regions
    @test grid.row == rows
    @test grid.col == cols
    @test grid.name == names
    @test all(isempty(meta) for meta in grid.metadata)  # Metadata should be empty
    
    # Names with empty strings (should default to regions)
    names_with_empty = ["California", "", "Texas"]
    grid_empty = GeoGrid(regions, rows, cols, names_with_empty)
    @test grid_empty.name == ["California", "NY", "Texas"]  # Empty name defaults to region
    
    # Names with whitespace (should default to regions)
    names_with_whitespace = ["California", "   ", "Texas"]
    grid_whitespace = GeoGrid(regions, rows, cols, names_with_whitespace)
    @test grid_whitespace.name == ["California", "NY", "Texas"]  # Whitespace name defaults to region
    
    # Error cases - mismatched lengths
    @test_throws ArgumentError GeoGrid(["A", "B"], [1, 2], [1, 2], ["Name A"])  # names shorter
    @test_throws ArgumentError GeoGrid(["A"], [1], [1], ["Name A", "Name B"])  # names longer
    
    # Error cases - invalid values (same as 3-arg version)
    @test_throws ArgumentError GeoGrid([""], [1], [1], ["Name"])  # Empty region name
    @test_throws ArgumentError GeoGrid(["A"], [0], [1], ["Name"])  # Zero row
    @test_throws ArgumentError GeoGrid(["A"], [1], [0], ["Name"])  # Zero col
end

@testset "GeoGrid Constructor - Vectors (5 args)" begin
    # Basic construction with names and metadata
    regions = ["CA", "NY", "TX"]
    rows = [1, 1, 2]
    cols = [1, 2, 1]
    names = ["California", "New York", "Texas"]
    metadata = [
        Dict{String,Any}("population" => 39538223, "area" => 163696),
        Dict{String,Any}("population" => 20201249, "area" => 54555),
        Dict{String,Any}("population" => 29145505, "area" => 268596)
    ]
    
    grid = GeoGrid(regions, rows, cols, names, metadata)
    
    @test grid isa GeoGrid
    @test length(grid) == 3
    @test grid.region == regions
    @test grid.row == rows
    @test grid.col == cols
    @test grid.name == names
    @test grid.metadata == metadata
    
    # Check metadata access
    ca_idx = findfirst(==(("CA")), grid.region)
    @test grid.metadata[ca_idx]["population"] == 39538223
    @test grid.metadata[ca_idx]["area"] == 163696
    
    # Empty metadata
    empty_metadata = [Dict{String,Any}(), Dict{String,Any}(), Dict{String,Any}()]
    grid_empty_meta = GeoGrid(regions, rows, cols, names, empty_metadata)
    @test all(isempty(meta) for meta in grid_empty_meta.metadata)
    
    # Names with empty strings (should default to regions)
    names_with_empty = ["California", "", "Texas"]
    grid_empty = GeoGrid(regions, rows, cols, names_with_empty, metadata)
    @test grid_empty.name == ["California", "NY", "Texas"]
    
    # Error cases - mismatched lengths
    @test_throws ArgumentError GeoGrid(["A"], [1], [1], ["Name"], [Dict{String,Any}(), Dict{String,Any}()])  # metadata longer
    @test_throws ArgumentError GeoGrid(["A", "B"], [1, 2], [1, 2], ["N1", "N2"], [Dict{String,Any}()])  # metadata shorter
    
    # Error cases - invalid values (same as other versions)
    @test_throws ArgumentError GeoGrid([""], [1], [1], ["Name"], [Dict{String,Any}()])  # Empty region name
    @test_throws ArgumentError GeoGrid(["A"], [0], [1], ["Name"], [Dict{String,Any}()])  # Zero row
    @test_throws ArgumentError GeoGrid(["A"], [1], [0], ["Name"], [Dict{String,Any}()])  # Zero col
end

