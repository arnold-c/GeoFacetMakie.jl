using GeoFacetMakie
using Test
using DataFrames
using Makie

@testset "GeoFacetMakie.jl" begin
    # Package loading tests
    include("package_loading.jl")

    # Type definition tests
    include("types/grid_entry.jl")
    include("types/geo_grid.jl")

    # Grid utilities tests
    include("grid_utils/grid_operations.jl")
    include("grid_utils/grid_loader.jl")

    # Grid edge cases tests
    include("geogrid_edge_cases.jl")

    # Plotting functionality tests
    include("plotting/geofacet_core.jl")
    include("plotting/data_processing.jl")
    include("plotting/axis_management.jl")
    include("plotting/legend_detection.jl")
end

using JET
@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(GeoFacetMakie, target_modules = (GeoFacetMakie,))))
end

@testset "QA with Aqua" begin
    import Aqua
    # Disable persistent_tasks check as Makie backends create background rendering tasks
    Aqua.test_all(GeoFacetMakie; persistent_tasks = false)
end
