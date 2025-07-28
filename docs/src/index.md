# GeoFacetMakie.jl

*Create geographically faceted visualizations with Julia and Makie.jl*

# [![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
# [![Build Status](https://github.com/arnold-c/GeoFacetMakie.jl/workflows/CI/badge.svg)](https://github.com/arnold-c/GeoFacetMakie.jl/actions?query=workflow%3ACI)
# [![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://arnold-c.github.io/GeoFacetMakie.jl/stable)
# [![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://arnold-c.github.io/GeoFacetMakie.jl/dev)
#
## Overview

GeoFacetMakie.jl brings the power of **geofaceting** to Julia's Makie.jl ecosystem. Inspired by the R `geofacet` package, it allows you to arrange plots in geographical layouts that preserve spatial relationships while enabling detailed comparisons across regions.

### What is Geofaceting?

Geofaceting is a visualization technique that arranges small multiples (facets) of plots according to their geographic positions. This approach:

- **Preserves spatial context** - Viewers can easily understand geographic relationships
- **Enables detailed comparison** - Each region gets its own dedicated plot space
- **Scales effectively** - Works well with many regions without overcrowding
- **Maintains familiarity** - Uses recognizable geographic layouts

## Key Features

- 🗺️ **Geographic layouts** - Arrange plots to match real-world geography
- 📊 **Flexible plotting** - Support for any Makie.jl plot type
- 🔗 **Axis linking** - Link axes across facets for easy comparison
- 🎨 **Full customization** - Complete control over styling and appearance
- ⚡ **High performance** - Efficient rendering of complex multi-panel plots
- 🧩 **Extensible grids** - Built-in grids plus support for custom layouts

## Quick Start

```julia
using GeoFacetMakie, DataFrames, CairoMakie

# Sample data
data = DataFrame(
    state = ["CA", "TX", "NY", "FL"],
    population = [39.5, 29.1, 19.8, 21.5],
    year = [2023, 2023, 2023, 2023]
)

# Define plotting function
function plot_bars!(gl, data; kwargs...)
    ax = Axis(gl[1, 1]; kwargs...)
    barplot!(ax, [1], data.population, color = :steelblue)
    ax.title = data.state[1]
end

# Create geofaceted plot
geofacet(data, :state, plot_bars!;
         figure_kwargs = (size = (800, 600),),
         common_axis_kwargs = (ylabel = "Population (M)",))
```

## Installation

```julia
using Pkg
Pkg.add("GeoFacetMakie")
```

!!! note "Makie Backend Required"
    GeoFacetMakie.jl requires a Makie backend. Install one of:
    - `CairoMakie.jl` for static plots
    - `GLMakie.jl` for interactive plots
    - `WGLMakie.jl` for web-based plots

## Getting Started

```@contents
Pages = [
    "installation.md",
    "quickstart.md",
    "tutorials/basic_usage.md"
]
Depth = 1
```

## Examples Gallery

| Basic Plots | Time Series | Advanced Features |
|-------------|-------------|-------------------|
| ![Population bars](examples/population_bars.png) | ![Time series](examples/population_timeseries.png) | ![Dual timeseries](examples/full_states_dual_timeseries.png) |
| [Basic plotting tutorial](tutorials/basic_usage.md) | [Time series tutorial](examples/timeseries.md) | [Advanced features](tutorials/advanced_features.md) |

## Package Ecosystem

GeoFacetMakie.jl integrates seamlessly with the Julia data science ecosystem:

- **[Makie.jl](https://makie.juliaplots.org/)** - High-performance plotting backend
- **[DataFrames.jl](https://dataframes.juliadata.org/)** - Data manipulation and grouping
- **[CSV.jl](https://csv.juliadata.org/)** - Data loading from files
- **[StatsPlots.jl](https://github.com/JuliaPlots/StatsPlots.jl)** - Statistical plotting recipes

## Contributing

We welcome contributions! See our [Contributing Guide](guides/contributing.md) for details on:

- Reporting bugs and requesting features
- Contributing code and documentation
- Adding new geographic grids
- Improving performance and functionality

## Citation

If you use GeoFacetMakie.jl in your research, please cite:

```bibtex
@software{geofacetmakie2024,
  author = {Arnold, Callum},
  title = {GeoFacetMakie.jl: Geographic Faceting for Julia},
  url = {https://github.com/arnold-c/GeoFacetMakie.jl},
  year = {2024}
}
```

## License

GeoFacetMakie.jl is licensed under the [MIT License](https://github.com/arnold-c/GeoFacetMakie.jl/blob/master/LICENSE).
