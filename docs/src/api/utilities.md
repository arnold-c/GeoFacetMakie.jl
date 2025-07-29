# Utilities

This page documents utility functions and helper tools in GeoFacetMakie.jl for data preparation, validation, and workflow optimization.

## Internal Utilities

The following functions are used internally by GeoFacetMakie.jl but are not exported. They are documented here for completeness and for developers who may need to understand the package internals.

### Data Processing

The package includes several internal functions for processing data:

- `_prepare_grouped_data(data, region_col)` - Groups data by region column
- `_get_available_regions(grouped_data, region_col)` - Extracts available region codes
- `_has_region_data(available_regions, region_code)` - Checks if region data exists
- `_get_region_data(grouped_data, region_col, region_code)` - Gets data for specific region
- `_has_labeled_plots(fig)` - Checks if figure contains plots with labels

### Axis Management

Internal axis management functions:

- `_get_yaxis_position(axis_kwargs)` - Gets y-axis position from kwargs
- `_merge_axis_kwargs(common_kwargs, per_axis_kwargs_list, per_axis_decoration_kwargs, num_axes)` - Merges axis kwargs with proper precedence
- `collect_gl_axes_by_position(layouts)` - Collects axes from GridLayouts by position
- `hide_all_decorations!(layout)` - Hides all decorations in a GridLayout

## Usage Examples

### Working with Predefined Grids

```julia
# Check how many predefined grids are available
count = get_predefined_grids_count()
println("Available predefined grids: ", count)

# List all available grids
available = list_available_grids()
println("First 5 grids: ", join(available[1:5], ", "))

# Load a specific grid
grid = load_grid_from_csv("us_state_grid1")
```

### Grid Validation and Information

```julia
# Validate a grid
try
    validate_grid(grid)
    println("Grid is valid")
catch e
    println("Grid validation failed: ", e)
end

# Get grid information
max_row, max_col = grid_dimensions(grid)
println("Grid dimensions: $(max_row) × $(max_col)")

# Check if grid is a complete rectangle
if is_complete_rectangle(grid)
    println("Grid forms a complete rectangle")
else
    println("Grid has gaps")
end

# Get all regions in the grid
regions = get_regions(grid)
println("Grid contains $(length(regions)) regions")
```

### Region Queries

```julia
# Check if a region exists
if has_region(grid, "CA")
    println("California is in the grid")
end

# Get position of a region
pos = get_position(grid, "CA")
if !isnothing(pos)
    println("California is at position $(pos)")
end

# Get region at a specific position
region = get_region_at(grid, 2, 3)
if !isnothing(region)
    println("Region at (2,3): $(region)")
end
```

### Neighbor Detection

```julia
# Check neighbors for axis decoration hiding
region = "TX"

if has_neighbor_below(grid, region)
    println("$(region) has a neighbor below")
end

if has_neighbor_left(grid, region)
    println("$(region) has a neighbor to the left")
end

if has_neighbor_right(grid, region)
    println("$(region) has a neighbor to the right")
end

if has_neighbor_above(grid, region)
    println("$(region) has a neighbor above")
end
```

## Performance Notes

### Grid Operations

Most grid utility functions are optimized for performance:

- `has_neighbor_*` functions use vectorized operations for efficiency
- `get_position` and `get_region_at` use efficient search algorithms
- Grid validation is performed once during construction

### Memory Usage

- GeoGrid uses StructArray for efficient memory layout
- Neighbor detection functions avoid creating temporary arrays
- Grid metadata is stored efficiently in dictionaries

## See Also

- [Core Functions](core.md) - Main plotting functions
- [Grid Operations](grids.md) - Working with geographic grids
