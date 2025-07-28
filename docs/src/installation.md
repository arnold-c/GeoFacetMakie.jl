# Installation

## Requirements

GeoFacetMakie.jl requires:

- **Julia ≥ 1.10** - Download from [julialang.org](https://julialang.org/downloads/)
- **A Makie backend** - Choose one based on your needs

## Installing GeoFacetMakie.jl

### From the Julia Package Registry

```julia
using Pkg
Pkg.add("GeoFacetMakie")
```

### Development Version

To install the latest development version:

```julia
using Pkg
Pkg.add(url="https://github.com/arnold-c/GeoFacetMakie.jl")
```

## Installing a Makie Backend

GeoFacetMakie.jl requires a Makie backend for rendering plots. Choose one:

### CairoMakie.jl (Recommended for most users)

Best for static plots, publications, and file output:

```julia
Pkg.add("CairoMakie")
```

**Pros:**
- High-quality static output (PNG, PDF, SVG)
- Excellent for publications and reports
- Fast rendering for static plots
- No display dependencies

**Cons:**
- No interactivity
- Requires system graphics libraries

### GLMakie.jl

Best for interactive exploration and development:

```julia
Pkg.add("GLMakie")
```

**Pros:**
- Full interactivity (zoom, pan, rotate)
- Real-time plot updates
- Great for data exploration
- Hardware-accelerated rendering

**Cons:**
- Requires OpenGL support
- May have display issues on some systems
- Larger memory footprint

### WGLMakie.jl

Best for web applications and Jupyter notebooks:

```julia
Pkg.add("WGLMakie")
```

**Pros:**
- Works in web browsers
- Great for Jupyter/Pluto notebooks
- No local display requirements
- Interactive in web contexts

**Cons:**
- Requires web browser
- Limited to web environments
- May have performance limitations

## Verification

Test your installation:

```julia
using GeoFacetMakie
using CairoMakie  # or GLMakie, WGLMakie

# Create a simple test plot
using DataFrames
test_data = DataFrame(state = ["CA", "TX"], value = [1, 2])

geofacet(test_data, :state,
         (gl, data; kwargs...) -> begin
             ax = Axis(gl[1, 1]; kwargs...)
             barplot!(ax, [1], data.value)
             ax.title = data.state[1]
         end)
```

If this runs without errors, your installation is successful!

## Troubleshooting

### Common Issues

#### "Package not found" error
Make sure you're using Julia ≥ 1.10:
```julia
versioninfo()
```

#### Backend-related errors
Ensure you have a Makie backend installed and loaded:
```julia
using CairoMakie  # or your chosen backend
```

#### Graphics/display issues
For CairoMakie on Linux, you may need system graphics libraries:
```bash
# Ubuntu/Debian
sudo apt-get install libcairo2-dev libpango1.0-dev

# CentOS/RHEL
sudo yum install cairo-devel pango-devel
```

#### Performance issues
For large datasets or complex plots:
- Use CairoMakie for static output
- Consider data aggregation/sampling
- See our [Performance Guide](guides/performance.md)

### Getting Help

If you encounter issues:

1. Check our [Troubleshooting Guide](guides/troubleshooting.md)
2. Search [existing issues](https://github.com/arnold-c/GeoFacetMakie.jl/issues)
3. Create a [new issue](https://github.com/arnold-c/GeoFacetMakie.jl/issues/new) with:
   - Julia version (`versioninfo()`)
   - Package versions (`Pkg.status()`)
   - Minimal reproducible example
   - Error messages and stack traces

## Next Steps

- [Quick Start Guide](quickstart.md) - Get up and running quickly
- [Basic Usage Tutorial](tutorials/basic_usage.md) - Learn the fundamentals
- [Examples Gallery](examples/gallery.md) - See what's possible
