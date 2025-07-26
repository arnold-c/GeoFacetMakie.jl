using GeoFacetMakie
using Test
using DataFrames
using Makie

@testset "GeoFacetMakie.jl" begin
    @testset "Package Loading" begin
        @test isa(GeoFacetMakie, Module)
        @test isdefined(GeoFacetMakie, :Makie)
        @test isdefined(GeoFacetMakie, :DataFrames)
    end
end

using JET
@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(GeoFacetMakie, target_modules=(GeoFacetMakie,))))
end

@testset "QA with Aqua" begin
    import Aqua
    Aqua.test_all(GeoFacetMakie)
end


