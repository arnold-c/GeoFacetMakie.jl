# GeoFacetMakie Examples

This directory contains example scripts demonstrating the functionality of GeoFacetMakie.jl.

## Available Examples

### 🚀 `basic_demo.jl` - Core Functionality Demo
Basic introduction to GeoFacetMakie with simple examples.

### 🗺️ `full_states_timeseries.jl` - Comprehensive State Analysis
Advanced example with all 50 US states featuring dual time series plots.

## Running the Examples

From the package root directory, run:

```bash
# Basic functionality demo
julia --project examples/basic_demo.jl

# Comprehensive dual time series demo
julia --project examples/full_states_timeseries.jl
```

## What the Demos Show

### 🚀 `basic_demo.jl` - Core Functionality

### 📊 **Example 1: Population Bar Charts**
- Basic geofaceted bar plots showing state populations
- Custom styling with titles and axis labels
- Demonstrates the core `geofacet()` function

### 💰 **Example 2: GDP vs Unemployment Scatter Plot**
- Scatter plots with linked axes (`:both`)
- Shows how axis linking enables easy cross-state comparison
- Demonstrates multi-variable visualization

### 📈 **Example 3: Time Series Plots**
- Simulated population growth over time
- Y-axis linking (`:y`) for temporal comparison
- Shows how to handle time-based data

### ⚠️ **Example 4: Error Handling**
- Demonstrates graceful handling of missing regions
- Shows the `missing_regions = :skip` option
- Validates robust error recovery

### 🗺️ `full_states_timeseries.jl` - Advanced Features

### 📈 **Comprehensive State Coverage**
- All 50 US states including Alaska
- 15 years of realistic economic time series data (2009-2023)
- Economic event modeling (2008 financial crisis, COVID-19 impact)

### 🎯 **Dual Time Series Implementation**
- Named mutating plotting function (`dual_timeseries_plot!`)
- Population growth (left y-axis, blue line)
- GDP per capita (right y-axis, red line)
- Secondary y-axis implementation with proper styling

### 🔗 **Advanced Axis Management**
- X-axis linking for temporal comparison across states
- Dual y-axes with different scales and colors
- Comprehensive data validation and error handling

### 📊 **Multiple Output Variants**
- Full 50-state comprehensive view
- Focused top-20 states version for clarity
- Realistic data simulation with economic volatility

## Output Files

### Basic Demo (`basic_demo.jl`)
- `population_bars.png` - State population bar charts
- `gdp_unemployment_scatter.png` - Economic indicators scatter plot  
- `population_timeseries.png` - Population growth time series
- `error-handling_barplot.png` - Error handling demonstration

### Full States Demo (`full_states_timeseries.jl`)
- `full_states_dual_timeseries.png` - All 50 states with dual time series
- `top20_states_dual_timeseries.png` - Top 20 most populous states focused view

## Key Features Demonstrated

### Core Features
- **Multiple plot types**: `barplot!`, `scatter!`, `lines!`
- **Axis linking**: `:none`, `:x`, `:y`, `:both`
- **Customization**: `figure_kwargs`, `axis_kwargs`
- **Error handling**: Missing region management
- **Data flexibility**: Different data structures and types

### Advanced Features
- **Named plotting functions**: Reusable, testable plotting logic
- **Dual y-axes**: Secondary axis implementation
- **Comprehensive data**: All 50 US states + realistic time series
- **Economic modeling**: Crisis events, volatility, growth patterns
- **Multiple output formats**: Full and focused visualizations

## Next Steps

1. **Modify the examples** - Change colors, sizes, or plot types
2. **Try different grids** - Use `us_state_grid2`, `us_state_grid3`, etc.
3. **Add your own data** - Replace sample data with real datasets
4. **Experiment with styling** - Explore Makie's extensive customization options

## Requirements

- Julia 1.10+
- GeoFacetMakie.jl
- DataFrames.jl
- **Makie Backend**: You must choose and install one:
  - `CairoMakie.jl` (for static plots)
  - `GLMakie.jl` (for interactive plots)
  - `WGLMakie.jl` (for web-based plots)

**Note**: GeoFacetMakie.jl does not include a Makie backend by default. You must install and load your preferred backend before running the examples.

Happy plotting! 🗺️📊