"""
Tests for basic package loading and dependencies
"""

@testset "Package Loading" begin
    @test isa(GeoFacetMakie, Module)
    @test isdefined(GeoFacetMakie, :Makie)
    @test isdefined(GeoFacetMakie, :DataFrames)
end