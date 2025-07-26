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

### Core Components

```
GeoFacetMakie.jl
├── Core/
│   ├── GeoGrid.jl          # Grid definition structures
│   ├── DataInterface.jl    # DataFrames integration
│   └── LayoutEngine.jl     # Makie layout generation
├── Grids/
│   ├── USStates.jl         # US state grid definitions
│   ├── EUCountries.jl      # European Union grids
│   └── CustomGrids.jl      # Custom grid utilities
├── Plotting/
│   ├── GeoFacet.jl         # Main plotting interface
│   ├── PlotTypes.jl        # Supported plot types
│   └── Theming.jl          # Styling and themes
└── Utils/
    ├── Validation.jl       # Input validation
    └── Helpers.jl          # Utility functions
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

#### GeoGrid
```julia
struct GeoGrid
    name::String
    description::String
    positions::Dict{String, Tuple{Int, Int}}  # entity_name -> (row, col)
    dimensions::Tuple{Int, Int}               # (max_rows, max_cols)
    metadata::Dict{String, Any}               # additional information
end
```

#### GeoFacetSpec
```julia
struct GeoFacetSpec
    grid::GeoGrid
    entity_column::Symbol
    plot_function::Function
    shared_axes::Bool
    show_missing::Bool
    custom_labels::Dict{String, String}
end
```

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

#### Grid Management
```julia
# List available grids
list_grids()

# Get specific grid
grid = get_grid(:us_state_grid2)

# Create custom grid
custom_grid = create_grid("my_regions",
                         Dict("North" => (1, 1),
                              "South" => (2, 1),
                              "East" => (1, 2),
                              "West" => (2, 2)))
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

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Establish core infrastructure and basic functionality

**Tasks**:
1. **Project Setup**
   - Initialize Julia package structure
   - Set up testing framework (using Test.jl)
   - Configure CI/CD pipeline
   - Create basic documentation structure

2. **Core Data Structures**
   - Implement `GeoGrid` struct and basic operations
   - Create validation functions for grid definitions
   - Implement grid serialization/deserialization

3. **Basic US States Grid**
   - Define primary US states grid layout
   - Include all 50 states + DC in logical positions
   - Add metadata (state codes, regions, etc.)

4. **Simple DataFrames Integration**
   - Basic groupby functionality
   - Entity name matching and validation
   - Handle missing entities gracefully

**Deliverables**:
- Working `GeoGrid` implementation
- Basic US states grid definition
- Simple data grouping functionality
- Initial test suite

### Phase 2: Core Plotting (Weeks 3-4)
**Goal**: Implement basic geofaceting with line plots

**Tasks**:
1. **Layout Engine**
   - Convert `GeoGrid` to Makie `GridLayout`
   - Handle empty positions and irregular shapes
   - Implement automatic sizing and spacing

2. **Basic Plotting Interface**
   - Implement `geofacet()` function for line plots
   - Support for basic customization options
   - Error handling and user feedback

3. **Axis Management**
   - Shared vs. independent axes options
   - Automatic axis labeling and scaling
   - Handle missing data gracefully

4. **First Working Examples**
   - Recreate basic examples from R geofacet
   - US unemployment data over time
   - State population trends

**Deliverables**:
- Working `geofacet()` function for line plots
- Makie GridLayout integration
- Basic examples and documentation
- Expanded test coverage

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

- **Julia Versions**: Support Julia 1.6+ (LTS and current)
- **Makie Backends**: Full compatibility with CairoMakie, GLMakie, WGLMakie
- **DataFrames.jl**: Support current and recent versions
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
