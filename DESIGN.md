# GeoFacetMakie.jl Design Document

## Background

### What is Geofaceting?

Geofaceting is a data visualization technique that arranges plots of data for different geographical entities into a grid layout that preserves the approximate geographical relationships between those entities. This approach allows viewers to:

- Maintain spatial context when comparing data across regions
- Easily identify patterns that correlate with geographical proximity
- Create more intuitive visualizations for geographically-distributed data

### Inspiration: The R geofacet Package

The [R geofacet package](https://hafen.github.io/geofacet/) by Ryan Hafen provides this functionality for ggplot2. Key features include:

- **Predefined Grids**: Built-in layouts for US states, EU countries, and other geographical entities
- **Custom Grids**: Ability to define custom geographical arrangements
- **Flexible Integration**: Works seamlessly with ggplot2's grammar of graphics
- **Multiple Variants**: Different grid arrangements for the same geographical area

### Why Julia and Makie?

**Julia Advantages:**
- High-performance numerical computing
- Rich ecosystem for data science (DataFrames.jl, Statistics.jl, etc.)
- Growing visualization capabilities
- No dependency on R ecosystem

**Makie.jl Advantages:**
- Powerful and flexible plotting system
- Multiple backends (static, interactive, web-based)
- Sophisticated layout management via GridLayout
- Native support for complex multi-panel figures
- Excellent performance for large datasets

## Design Goals

### Primary Objectives

1. **Faithful Recreation**: Provide functionality equivalent to R's geofacet package
2. **Julia Native**: Pure Julia implementation leveraging the DataFrames.jl ecosystem
3. **Makie Integration**: Seamless integration with Makie's plotting and theming system
4. **Performance**: Efficient handling of large datasets and complex layouts
5. **Extensibility**: Easy addition of new geographical grids and plot types

### User Experience Goals

1. **Intuitive API**: Simple, discoverable interface similar to Makie's existing patterns
2. **Flexible Data Input**: Support for various data formats and structures
3. **Customization**: Extensive theming and layout customization options
4. **Documentation**: Comprehensive examples and tutorials

## Architecture Overview

### Current Project Structure

```
GeoFacetMakie.jl
├── src/
│   ├── GeoFacetMakie.jl    # Main module file
│   ├── structs.jl          # Core data structures (GeoGrid)
│   ├── grid_operations.jl  # Grid utility functions
│   ├── grid_loader.jl      # CSV grid loading functionality
│   ├── geofacet.jl         # Main plotting interface
│   └── data/grids/         # Predefined grid CSV files
│       ├── us_state_grid1.csv
│       ├── us_state_grid2.csv
│       ├── us_state_grid3.csv
│       ├── us_state_without_DC_grid1.csv
│       ├── us_state_without_DC_grid2.csv
│       ├── us_state_without_DC_grid3.csv
│       └── us_state_contiguous_grid1.csv
├── test/                   # Comprehensive test suite
├── examples/               # Example scripts and outputs
└── docs/                   # Documentation
```

### Data Flow

```
Raw Data (DataFrame)
    ↓
Group by Geographic Entity (groupby)
    ↓
Map to Grid Positions (GeoGrid)
    ↓
Create Makie GridLayout
    ↓
Apply Plotting Function to Each Group
    ↓
Final Geofaceted Figure
```

## Technical Specifications

### Core Data Structures

#### GeoGrid (Current Implementation)
```julia
struct GeoGrid
    name::String
    positions::Dict{String, Tuple{Int, Int}}  # entity_name -> (row, col)

    # Constructor with validation:
    # - Region names cannot be empty or whitespace-only
    # - Grid positions must be positive integers (≥ 1)
    # - No two regions can occupy the same position
end
```

**Available Grid Operations:**
- `grid_dimensions(grid)` - Get (max_row, max_col)
- `validate_grid(grid)` - Check for position conflicts
- `has_region(grid, region)` - Check if region exists
- `get_position(grid, region)` - Get position of region
- `get_region_at(grid, row, col)` - Get region at position
- `get_regions(grid)` - Get all region names
- `is_complete_rectangle(grid)` - Check if grid is complete rectangle

### API Design

#### Primary Interface (Function-Passing Approach)

The core design philosophy emphasizes passing user-defined plotting functions to a wrapper that applies them across geographical facets. This provides maximum flexibility while handling coordination challenges.

```julia
# Function-passing style (primary approach)
function plot_single_facet(df, ax)
    lines!(ax, df.year, df.unemployment_rate, color = :blue)
    scatter!(ax, df.year, df.unemployment_rate, markersize = 8)
end

geofacet(data, :state, plot_single_facet;
         grid = us_state_grid,
         shared_axes = true)

# Convenience wrapper for simple cases
geofacet(data, :state, :year, :unemployment_rate;
         grid = us_state_grid,
         plot_type = :line)
```

#### API Design Challenges and Solutions

**Challenge 1: Global Axis Coordination**
When `shared_axes=true`, the wrapper must coordinate axis properties across facets while user functions operate on individual axes.

*Solution: Two-pass approach*
```julia
function geofacet(data, entity_col, plot_func; shared_axes=true, grid=us_state_grid)
    # Pass 1: Collect axis information from dry run
    axis_bounds = compute_global_limits(data, entity_col, plot_func)

    # Pass 2: Apply plots with coordinated axes
    apply_with_shared_axes(data, entity_col, plot_func, axis_bounds, grid)
end
```

**Challenge 2: Theme Application**
Ensuring consistent theming across facets while allowing customization.

*Solution: Theme context management*
```julia
function geofacet(data, entity_col, plot_func; theme=nothing, kwargs...)
    grouped_data = groupby(data, entity_col)
    fig = Figure()

    # Create axes for each grid position
    axes_dict = create_geo_axes(fig, grid)

    # Apply plotting with or without theme
    if theme === nothing
        plot_objects = apply_plots(grouped_data, axes_dict, plot_func)
    else
        plot_objects = with_theme(theme) do
            apply_plots(grouped_data, axes_dict, plot_func)
        end
    end

    # Handle shared axes coordination
    if shared_axes
        coordinate_axes!(axes_dict, plot_objects)
    end

    return fig
end
```

**Challenge 3: Legend and Colorbar Management**
Multiple facets creating conflicting legends requires centralized coordination.

*Solution: Collect and unify plot objects*
```julia
# User plotting function returns plot objects
function plot_single_facet(df, ax)
    p1 = lines!(ax, df.year, df.unemployment_rate, color = :blue, label = "Rate")
    p2 = scatter!(ax, df.year, df.unemployment_rate, markersize = 8)
    return [p1, p2]  # Return for legend coordination
end

# Wrapper collects all plot objects for unified legend
plot_objects = []
for (entity, ax) in entity_axis_pairs
    plots = plot_func(get_data(entity), ax)
    append!(plot_objects, plots)
end

# Create unified legend from collected objects
create_unified_legend(fig, plot_objects, :right)
```

#### Grid Management (Current Implementation)
```julia
# List available predefined grids
available_grids = list_available_grids()

# Load specific predefined grids
us_grid = load_us_state_grid(1)  # versions 1, 2, or 3
us_no_dc = load_us_state_grid_without_dc(1)
contiguous = load_us_contiguous_grid()

# Load any grid by name
grid = load_grid("us_state_grid2")

# Load custom grid from CSV
custom_grid = load_grid_from_csv("path/to/custom.csv")

# Create grid programmatically
positions = Dict("CA" => (1, 1), "NY" => (1, 2), "TX" => (2, 1))
custom_grid = GeoGrid("my_regions", positions)
```

### Integration with DataFrames.jl

The package leverages DataFrames.jl's grouping capabilities with careful attention to Makie's actual patterns:

```julia
# Realistic internal workflow
function geofacet(data::DataFrame, entity_col::Symbol, plot_func::Function;
                  grid::GeoGrid = us_state_grid, shared_axes::Bool = true)

    # Group data by geographical entity
    grouped_data = groupby(data, entity_col)

    # Create figure and axes dictionary
    fig = Figure()
    axes_dict = Dict{String, Axis}()

    # Create axes for each grid position
    for (entity, (row, col)) in grid.positions
        axes_dict[entity] = Axis(fig[row, col])
    end

    # Apply plotting function to each group
    plot_objects = []
    for (key, subdf) in pairs(grouped_data)
        entity_name = string(key[entity_col])
        if haskey(axes_dict, entity_name)
            ax = axes_dict[entity_name]
            plot_obj = plot_func(subdf, ax)
            push!(plot_objects, plot_obj)
        end
    end

    # Coordinate axes if requested
    if shared_axes
        link_axes!(collect(values(axes_dict)))
    end

    return fig
end
```

#### Error Handling Considerations

- **Missing Entities**: Gracefully handle entities in data not present in grid
- **Empty Groups**: Handle groups with no data points
- **Plot Function Failures**: Catch and report errors in user plotting functions
- **Type Stability**: Ensure plotting function signatures are well-defined

### Makie Integration Strategy

#### Layout Management
- Use `GridLayout` for positioning individual plots
- Support for irregular grids with empty positions
- Automatic spacing and sizing based on content

#### Plot Types Support
- **Lines**: Time series and trend data
- **Scatter**: Point data and correlations
- **Heatmaps**: Intensity and density data
- **Bar Charts**: Categorical comparisons
- **Custom**: User-defined plotting functions

#### Theming Integration
- Respect Makie's global themes using `with_theme()` pattern
- Provide geofacet-specific theme options
- Support for per-facet customization through axis setup functions

#### Implementation Notes
- Use explicit loops rather than functional programming patterns for clarity
- Store plot objects for legend coordination rather than attempting complex functional composition
- Follow Makie's established patterns for layout and theming rather than inventing new abstractions

## Implementation Plan

### Phase 1: Foundation ✅ COMPLETED
**Goal**: Establish core infrastructure and basic functionality

**Completed Tasks**:
1. **Project Setup** ✅
   - Julia package structure initialized
   - Testing framework set up (Test.jl, JET.jl, Aqua.jl)
   - CI/CD pipeline configured (GitHub Actions)
   - Documentation structure created

2. **Core Data Structures** ✅
   - `GeoGrid` struct implemented with validation
   - Grid operations functions created (grid_operations.jl)
   - CSV loading functionality implemented

3. **US States Grids** ✅
   - Multiple US state grid layouts (versions 1, 2, 3)
   - Variants: with/without DC, contiguous states only
   - All grids stored as CSV files in src/data/grids/

4. **Grid Loading Infrastructure** ✅
   - CSV parsing with validation
   - Predefined grid loading functions
   - Grid listing and discovery functionality

**Deliverables** ✅:
- Working `GeoGrid` implementation
- Multiple US state grid definitions
- Comprehensive grid loading system
- Extensive test suite covering all functionality

### Phase 2: Core Plotting 🚧 IN PROGRESS
**Goal**: Implement basic geofaceting with plotting functionality

**Current Status**:
1. **Basic Plotting Interface** ✅
   - `geofacet()` function implemented in geofacet.jl
   - Function-passing approach for user-defined plotting
   - Basic error handling and validation

2. **Layout Engine** 🚧
   - Makie Figure and GridLayout integration
   - Support for irregular grids with empty positions
   - Axis creation and management

3. **Examples and Testing** ✅
   - Basic examples in examples/ directory
   - Test suite covering geofacet functionality
   - Sample data and plotting functions

**Next Tasks**:
- Complete axis coordination (shared vs. independent)
- Enhanced error handling and user feedback
- Performance optimization for large datasets
- Additional plot type support beyond basic functions

### Phase 3: Enhanced Functionality (Weeks 5-6)
**Goal**: Add multiple plot types and customization options

**Tasks**:
1. **Multiple Plot Types**
   - Scatter plots
   - Bar charts
   - Heatmaps
   - Custom plotting functions

2. **Advanced Customization**
   - Theming integration
   - Custom labels and titles
   - Color schemes and styling
   - Legend and colorbar management

3. **Additional Grids**
   - Alternative US state layouts
   - Basic European Union grid
   - Framework for custom grids

4. **Performance Optimization**
   - Efficient data processing
   - Memory usage optimization
   - Large dataset handling

**Deliverables**:
- Support for multiple plot types
- Advanced customization options
- Additional predefined grids
- Performance benchmarks

### Phase 4: Polish and Documentation (Weeks 7-8)
**Goal**: Production-ready package with comprehensive documentation

**Tasks**:
1. **Documentation**
   - Comprehensive API documentation
   - Tutorial notebooks
   - Gallery of examples
   - Migration guide from R geofacet

2. **Testing and Validation**
   - Comprehensive test suite
   - Visual regression tests
   - Performance tests
   - Cross-platform validation

3. **Package Polish**
   - Error message improvements
   - API consistency review
   - Code organization and cleanup
   - Prepare for registration

4. **Community Features**
   - Grid contribution guidelines
   - Custom grid examples
   - Integration examples with other packages

**Deliverables**:
- Complete documentation
- Production-ready codebase
- Comprehensive test suite
- Package ready for Julia registry

## Technical Considerations

### Performance Requirements

- **Large Datasets**: Efficiently handle datasets with millions of rows
- **Many Facets**: Support for grids with 50+ entities
- **Interactive Performance**: Smooth interaction in GLMakie backend
- **Memory Efficiency**: Minimize memory footprint for large visualizations

### Compatibility Requirements

- **Julia Versions**: Support Julia 1.10+ (as specified in Project.toml)
- **Makie Backends**: Full compatibility with CairoMakie, GLMakie (current dependencies)
- **DataFrames.jl**: Support version 1+ (as specified in Project.toml)
- **Cross-Platform**: Windows, macOS, Linux support

### Error Handling Strategy

- **Graceful Degradation**: Handle missing entities without failing
- **Informative Messages**: Clear error messages with suggestions
- **Validation**: Early validation of inputs with helpful feedback
- **Debugging Support**: Verbose modes for troubleshooting

## Future Enhancements

### Potential Extensions

1. **Interactive Features**
   - Brushing and linking between facets
   - Zoom and pan coordination
   - Interactive legends and filters

2. **Advanced Grids**
   - Hierarchical geographical arrangements
   - Time-based geographical changes
   - 3D geographical layouts

3. **Integration Opportunities**
   - GeoMakie.jl integration for map overlays
   - PlutoUI.jl for interactive notebooks
   - AlgebraOfGraphics.jl compatibility

4. **Performance Optimizations**
   - GPU acceleration for large datasets
   - Streaming data support
   - Parallel processing for independent facets

### Community Contributions

- **Grid Definitions**: Community-contributed geographical grids
- **Plot Types**: Additional specialized plot types
- **Themes**: Curated theme collections
- **Examples**: Domain-specific example galleries

## Success Metrics

### Technical Metrics
- **Performance**: Handle 1M+ row datasets efficiently
- **Coverage**: Support for major geographical arrangements
- **Compatibility**: Work across all major Makie backends
- **Reliability**: Comprehensive test coverage (>90%)

### User Experience Metrics
- **Ease of Use**: Simple examples work in <5 lines of code
- **Documentation**: Complete API coverage with examples
- **Migration**: Clear path from R geofacet
- **Community**: Active usage and contributions

### Ecosystem Integration
- **Package Registry**: Successful registration in Julia General registry
- **Dependencies**: Minimal and stable dependency tree
- **Interoperability**: Works well with other Julia visualization packages
- **Maintenance**: Sustainable development and maintenance model

## Conclusion

GeoFacetMakie.jl aims to bring the powerful geofaceting visualization technique to the Julia ecosystem, leveraging the performance and flexibility of Julia and Makie.jl. By following this design document, we can create a package that not only matches the functionality of the R geofacet package but potentially exceeds it in performance and integration with the broader Julia data science ecosystem.

The phased implementation approach ensures steady progress while maintaining code quality and user experience. The focus on extensibility and community contributions will help the package grow and adapt to diverse use cases in the Julia community.
