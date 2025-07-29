"""
Tests for internal data processing functions in plotting functionality
"""

using Test
using DataFrames
using GeoFacetMakie

@testset "Data Processing Functions" begin
    # Test data
    test_data = DataFrame(
        state = ["CA", "NY", "TX", "ca", "ny"],  # Include case variations
        value = [100, 200, 150, 110, 210],
        year = [2020, 2020, 2020, 2021, 2021]
    )

    @testset "_prepare_grouped_data" begin
        # Test basic grouping
        grouped = GeoFacetMakie._prepare_grouped_data(test_data, :state)
        @test grouped isa DataFrames.GroupedDataFrame
        @test length(grouped) == 5  # 5 unique states (case sensitive)

        # Test that original data is preserved
        @test parent(grouped) === test_data

        # Test grouping by different column
        grouped_year = GeoFacetMakie._prepare_grouped_data(test_data, :year)
        @test length(grouped_year) == 2  # 2020 and 2021
    end

    @testset "_get_available_regions" begin
        grouped = GeoFacetMakie._prepare_grouped_data(test_data, :state)
        available = GeoFacetMakie._get_available_regions(grouped, :state)

        @test available isa Set{String}
        @test length(available) == 3  # Unique regions after uppercase conversion: CA, NY, TX
        @test "CA" in available
        @test "NY" in available
        @test "TX" in available
        # Both "ca" and "CA" should be converted to "CA"

        # Test case insensitive conversion
        @test all(region -> region == uppercase(region), available)
    end

    @testset "_has_region_data" begin
        grouped = GeoFacetMakie._prepare_grouped_data(test_data, :state)
        available = GeoFacetMakie._get_available_regions(grouped, :state)

        # Test case insensitive matching
        @test GeoFacetMakie._has_region_data(available, "CA") == true
        @test GeoFacetMakie._has_region_data(available, "ca") == true
        @test GeoFacetMakie._has_region_data(available, "Ca") == true
        @test GeoFacetMakie._has_region_data(available, "NY") == true
        @test GeoFacetMakie._has_region_data(available, "ny") == true
        @test GeoFacetMakie._has_region_data(available, "TX") == true
        @test GeoFacetMakie._has_region_data(available, "tx") == true

        # Test non-existent regions
        @test GeoFacetMakie._has_region_data(available, "FL") == false
        @test GeoFacetMakie._has_region_data(available, "WA") == false
        @test GeoFacetMakie._has_region_data(available, "") == false
    end

    @testset "_get_region_data" begin
        grouped = GeoFacetMakie._prepare_grouped_data(test_data, :state)

        # Test case insensitive retrieval
        ca_data = GeoFacetMakie._get_region_data(grouped, :state, "CA")
        @test ca_data isa DataFrames.SubDataFrame
        @test nrow(ca_data) == 1
        @test ca_data.state[1] == "CA"
        @test ca_data.value[1] == 100

        # Test case insensitive matching - will find first match
        ca_data_lower = GeoFacetMakie._get_region_data(grouped, :state, "ca")
        @test ca_data_lower isa DataFrames.SubDataFrame
        # Will find the first "CA" entry due to case-insensitive matching
        @test nrow(ca_data_lower) == 1
        @test ca_data_lower.state[1] == "CA"
        @test ca_data_lower.value[1] == 100

        # Test mixed case - should also find first match
        ca_data_mixed = GeoFacetMakie._get_region_data(grouped, :state, "Ca")
        @test ca_data_mixed isa DataFrames.SubDataFrame  # Should find a match due to case-insensitive search
        @test ca_data_mixed.state[1] == "CA"

        # Test non-existent region
        fl_data = GeoFacetMakie._get_region_data(grouped, :state, "FL")
        @test isnothing(fl_data)

        # Test empty string
        empty_data = GeoFacetMakie._get_region_data(grouped, :state, "")
        @test isnothing(empty_data)
    end
end

