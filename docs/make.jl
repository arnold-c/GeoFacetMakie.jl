# Documentation build script for GeoFacetMakie.jl
# See documentation at https://juliadocs.github.io/Documenter.jl/stable/
using Revise
Revise.revise()

using Documenter
using GeoFacetMakie


# Enable plot generation in documentation
ENV["GKSwstype"] = "100"  # For headless plot generation

makedocs(
    modules = [GeoFacetMakie],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://arnold-c.github.io/GeoFacetMakie.jl",
        assets = String[],
        # analytics = "G-XXXXXXXXXX",  # Replace with your Google Analytics ID
        edit_link = "main",
        sidebar_sitename = true,
    ),
    authors = "arnold-c",
    sitename = "GeoFacetMakie.jl",
    pages = [
        "Home" => "index.md",
        "Installation" => "installation.md",
        "Quick Start" => "quickstart.md",
        # "Tutorials" => [
        #     "Basic Usage" => "tutorials/basic_usage.md",
        #     "Customization" => "tutorials/customization.md",
        #     "Advanced Features" => "tutorials/advanced_features.md",
        #     "Data Preparation" => "tutorials/data_preparation.md",
        # ],
        # "Examples" => [
        #     "Gallery" => "examples/gallery.md",
        #     "Basic Plots" => "examples/basic_plots.md",
        #     "Time Series" => "examples/timeseries.md",
        #     "Custom Grids" => "examples/custom_grids.md",
        # ],
        "API Reference" => [
            "Core Functions" => "api/core.md",
            "Grid Operations" => "api/grids.md",
            "Utilities" => "api/utilities.md",
        ],
        # "Guides" => [
        #     "Troubleshooting" => "guides/troubleshooting.md",
        #     "Contributing" => "guides/contributing.md",
        # ],
        # "Reference" => [
        #     "Available Grids" => "reference/grids_reference.md",
        #     "Changelog" => "reference/changelog.md",
        # ],
    ],
    # strict = true,
    clean = true,
    # checkdocs = :exports,
    # doctest = false,
    # linkcheck = false,
    warnonly = [
        :doctest,
        :linkcheck,
        :missing_docs,
        :cross_references,
    ],
)

# Documentation deployment configuration
deploydocs(
    repo = "github.com/arnold-c/GeoFacetMakie.jl.git",
    push_preview = true,
    devbranch = "main",
    versions = ["stable" => "v^", "v#.#", "dev" => "main"],
)
