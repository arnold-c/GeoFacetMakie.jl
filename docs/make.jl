# Documentation build script for GeoFacetMakie.jl
# See documentation at https://juliadocs.github.io/Documenter.jl/stable/
using Documenter
using DocumenterVitepress
using GeoFacetMakie

gh_user = "arnold-c"
gh_repo_name = "GeoFacetMakie.jl"
repo = "github.com/$gh_user/$gh_repo_name.git"
devbranch = "main"
devurl = "dev"
docsbranch = "docs"
deploy_url = "https://geofacetmakie.callumarnold.com"

Documenter.makedocs(
    modules = [GeoFacetMakie],
    repo = Remotes.GitHub(gh_user, gh_repo_name),
    format = MarkdownVitepress(;
        repo = repo,
        devbranch = devbranch,
        devurl = devurl,
        deploy_url = deploy_url,
        md_output_path = ".",
        build_vitepress = false,
    ),
    authors = "arnold-c",
    sitename = gh_repo_name,
    pages = Any[
        "Home" => "index.md",
        "Installation" => "installation.md",
        "Quick Start" => "quickstart.md",
        "Tutorials" => [
            "Basic Usage" => "tutorials/basic_usage.md",
            "Advanced Usage" => "tutorials/multiple_axis_demo.md",
        ],
        "API Reference" => [
            "Core Functions" => "api/core.md",
            "Grid Operations" => "api/grids.md",
            "Available Grids" => "api/available-grids.md",
            "Utilities" => "api/utilities.md",
        ],
    ],
    warnonly = [
        :doctest,
        :linkcheck,
        :missing_docs,
        :cross_references,
        :example_block,
    ],

)

# Some setup is needed for documentation deployment, see “Hosting Documentation” and
# deploydocs() in the Documenter manual for more information.
DocumenterVitepress.deploydocs(
    repo = repo,
    target = joinpath(@__DIR__, "build"), # this is where Vitepress stores its output
    devbranch = devbranch,
    devurl = devurl,
    branch = docsbranch,
    push_preview = true
)
