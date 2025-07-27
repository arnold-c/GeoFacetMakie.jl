using GeoFacetMakie
using Test
using DataFrames
using Makie

@testset "GeoFacetMakie.jl" begin
    # Include all test files
    include("package_loading.jl")
    include("geogrid_construction.jl")
    include("geogrid_validation.jl")
    include("geogrid_querying.jl")
    include("geogrid_edge_cases.jl")
    include("grid_loading.jl")
    include("geofacet.jl")
end
# TODO: Re-enable once core functionality is complete
# using JET
# @testset "static analysis with JET.jl" begin
#     @test isempty(JET.get_reports(report_package(GeoFacetMakie, target_modules=(GeoFacetMakie,))))
# end

# @testset "QA with Aqua" begin
#     import Aqua
#     Aqua.test_all(GeoFacetMakie)
# end
