# see documentation at https://juliadocs.github.io/Documenter.jl/stable/

using Documenter, GeoFacetMakie

makedocs(
    modules = [GeoFacetMakie],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "arnold-c",
    sitename = "GeoFacetMakie.jl",
    pages = Any["index.md"],
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

# Some setup is needed for documentation deployment, see “Hosting Documentation” and
# deploydocs() in the Documenter manual for more information.
deploydocs(
    repo = "github.com/arnold-c/GeoFacetMakie.jl.git",
    push_preview = true
)
