# GeoFacetMakie.jl

A Julia package for creating geofaceted visualizations using Makie.jl.

## Overview

GeoFacetMakie.jl brings the power of geofaceting to Julia's Makie.jl ecosystem. 
Inspired by the R `geofacet` package, it allows you to arrange plots in 
geographical layouts that preserve spatial relationships while enabling 
detailed comparisons across regions.

## Quick Start

```julia
using GeoFacetMakie, DataFrames

# Define your plotting function
function plot_unemployment(df, ax)
    lines!(ax, df.year, df.unemployment_rate, color = :blue)
end

# Create geofaceted plot
geofacet(unemployment_data, :state, plot_unemployment; 
         grid = us_state_grid, shared_axes = true)
```

## API Reference

```@docs
GeoFacetMakie
geofacet
GeoGrid
```
