# Grid Operations

This page documents functions and utilities for working with geographic grids in GeoFacetMakie.jl.

## Grid Structure

### Grid Format

Geographic grids are DataFrames with a specific structure:

```julia
grid = DataFrame(
    code = ["CA", "TX", "NY"],     # Required: Region identifiers
    row = [2, 3, 1],               # Required: Grid row positions
    col = [1, 2, 3],               # Required: Grid column positions
    name = ["California", "Texas", "New York"]  # Optional: Full names
)
```

### Required Columns

- **`code`**: Unique identifiers for geographic regions (String)
- **`row`**: Grid row positions, starting from 1 (Integer)
- **`col`**: Grid column positions, starting from 1 (Integer)

### Optional Columns

- **`name`**: Full region names for display
- **`region`**: Higher-level groupings (e.g., "West", "South")
- **`population`**, **`area`**: Metadata for reference
- Any other descriptive columns

## Built-in Grids

### US State Grids

GeoFacetMakie.jl includes several pre-defined US state grids:

#### Available US State Grids
Several US state grid layouts are available through the `load_grid_from_csv()` function:

- `us_state_grid1`: Standard US state layout with Alaska and Hawaii positioned in the lower left
- `us_state_grid2`: Alternative arrangement with different positioning for western states
- `us_state_grid3`: Compact layout optimizing for space efficiency
- `us_state_contiguous_grid1`: Contiguous US states only (excludes Alaska and Hawaii)

```julia
using GeoFacetMakie
grid = load_grid_from_csv("us_state_grid1")
```

### Grid Comparison

| Grid | States | Alaska/Hawaii | Aspect Ratio | Best For |
|------|--------|---------------|--------------|----------|
| `us_state_grid1` | 50 + DC | Lower left | Wide | General use |
| `us_state_grid2` | 50 + DC | Alternative | Medium | Presentations |
| `us_state_grid3` | 50 + DC | Compact | Square | Small figures |
| `us_state_contiguous_grid1` | 48 | Excluded | Wide | Continental focus |

## Grid Functions

### Loading Grids

```@docs
list_available_grids
load_grid_from_csv
```

#### `load_grid_from_csv(name::String)`

Load a built-in grid by name.

```julia
# Load default US state grid
grid = load_grid_from_csv("us_state_grid1")

# Load contiguous states only
grid = load_grid_from_csv("us_state_contiguous_grid1")
```

#### `list_available_grids()`

Get a list of all available built-in grids.

```julia
available = list_available_grids()
println("Available grids: ", join(available, ", "))
```

## Creating Custom Grids

### Basic Custom Grid

```julia
# Simple custom grid
my_grid = DataFrame(
    code = ["A", "B", "C", "D"],
    row = [1, 1, 2, 2],
    col = [1, 2, 1, 2]
)
```

### Geographic Custom Grid

```julia
# European countries grid
europe_grid = DataFrame(
    code = ["UK", "FR", "DE", "IT", "ES"],
    name = ["United Kingdom", "France", "Germany", "Italy", "Spain"],
    row = [1, 2, 2, 3, 3],
    col = [1, 1, 2, 2, 1]
)
```

### Programmatic Grid Generation

```julia
function create_rectangular_grid(regions::Vector, ncols::Int)
    nrows = ceil(Int, length(regions) / ncols)

    grid = DataFrame(
        code = String[],
        row = Int[],
        col = Int[]
    )

    for (i, region) in enumerate(regions)
        row = ceil(Int, i / ncols)
        col = mod1(i, ncols)
        push!(grid, (code=region, row=row, col=col))
    end

    return grid
end

# Generate 3-column grid for any regions
regions = ["R1", "R2", "R3", "R4", "R5"]
auto_grid = create_rectangular_grid(regions, 3)
```

## Grid Utilities

### Grid Information

```@docs
grid_dimensions
is_complete_rectangle
get_regions
has_region
get_region_at
get_position
```

#### `grid_dimensions(grid::DataFrame)`

Get the dimensions of a grid.

```julia
dims = grid_dimensions(grid)
println("Grid is $(dims.rows) × $(dims.cols)")
```

Additional grid utility functions are planned for future versions.


## Grid Design Principles

### Geographic Accuracy vs Readability

Balance between maintaining geographic relationships and creating readable layouts:

```julia
# Geographically accurate (may be hard to read)
accurate_grid = DataFrame(
    code = ["FL", "GA", "SC", "NC"],
    row = [4, 3, 2, 1],  # True north-south order
    col = [1, 1, 1, 1]   # All in same column
)

# Readable compromise (sacrifices some accuracy)
readable_grid = DataFrame(
    code = ["FL", "GA", "SC", "NC"],
    row = [2, 2, 1, 1],  # Compressed vertically
    col = [1, 2, 1, 2]   # Spread horizontally
)
```

### Handling Special Cases

#### Irregular Geographies

```julia
# Grid with gaps for irregular shapes
irregular_grid = DataFrame(
    code = ["AK", "HI", "CA", "OR", "WA"],
    row = [1, 4, 3, 2, 1],     # Alaska and Hawaii separate
    col = [1, 1, 2, 2, 2]      # Gaps in layout
)
```

## Grid File Operations

### Saving and Loading

```julia
# Save custom grid
using CSV
CSV.write("my_custom_grid.csv", my_grid)

# Load custom grid
loaded_grid = CSV.read("my_custom_grid.csv", DataFrame)

# Validate after loading
issues = validate_grid(loaded_grid)
```

### Grid Formats

#### CSV Format
```csv
code,name,row,col
CA,California,3,1
OR,Oregon,2,1
WA,Washington,1,1
```

#### JSON Format (for complex grids)
```json
{
  "name": "West Coast Grid",
  "description": "Pacific coast states",
  "regions": [
    {"code": "CA", "name": "California", "row": 3, "col": 1},
    {"code": "OR", "name": "Oregon", "row": 2, "col": 1},
    {"code": "WA", "name": "Washington", "row": 1, "col": 1}
  ]
}
```

## Troubleshooting Grids

### Common Issues

**Duplicate positions:**
```julia
# Problem: Two regions at same position
# Solution: Check for duplicates
positions = [(r, c) for (r, c) in zip(grid.row, grid.col)]
duplicates = findall(x -> count(==(x), positions) > 1, positions)
```

**Missing regions:**
```julia
# Problem: Data regions not in grid
# Solution: Use subset_grid or add missing regions
data_regions = unique(data.state)
grid_regions = grid.code
missing = setdiff(data_regions, grid_regions)
```

**Sparse grids:**
```julia
# Problem: Grid has many empty spaces
# Solution: Optimize layout or use different arrangement
density = length(grid.code) / (maximum(grid.row) * maximum(grid.col))
if density < 0.3
    @warn "Grid is very sparse ($(round(density*100))% filled)"
end
```

## Best Practices

### 1. **Start with Built-ins**
Use existing grids when possible, customize only when needed.

### 2. **Validate Early and Often**
Always validate grids before using with real data.

### 3. **Test with Sample Data**
Create sample data to test grid layouts.

### 4. **Document Custom Grids**
Include metadata about grid design decisions.

### 5. **Consider Your Audience**
Prioritize readability over perfect geographic accuracy.

## See Also

# - [Custom Grids Tutorial](../examples/custom_grids.md) - Step-by-step grid creation
- [Core Functions](core.md) - Main GeoFacetMakie functions
# - [Basic Usage](../tutorials/basic_usage.md) - Using grids with data
# - [Examples Gallery](../examples/gallery.md) - Grids in action
