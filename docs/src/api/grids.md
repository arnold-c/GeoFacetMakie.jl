# Grid Operations

This page documents functions and utilities for working with geographic grids in GeoFacetMakie.jl.

## Grid Loading Functions

```@docs
load_grid_from_csv
list_available_grids
```

## Grid Utility Functions

```@docs
grid_dimensions
validate_grid
has_region
get_position
get_region_at
get_regions
is_complete_rectangle
```

## Neighbor Detection Functions

```@docs
has_neighbor_below
has_neighbor_left
has_neighbor_right
has_neighbor_above
```

## Predefined Grids

```@docs
get_predefined_grids_count
```

## Grid Structure

### Grid Format

Geographic grids are StructArrays with a specific structure:

```julia
# Create a simple grid
grid = GeoGrid(
    ["CA", "TX", "NY"],     # Region identifiers
    [2, 3, 1],              # Grid row positions
    [1, 2, 3]               # Grid column positions
)
```

### Required Fields

- **`region`**: Unique identifiers for geographic regions (String)
- **`row`**: Grid row positions, starting from 1 (Integer)
- **`col`**: Grid column positions, starting from 1 (Integer)
- **`name`**: Display names for regions (String, defaults to region)
- **`metadata`**: Additional metadata (Dict{String,Any})

## Built-in Grids

### Available Grids

GeoFacetMakie.jl includes many pre-defined grids from the geofacet collection:

```julia
# List all available grids
available = list_available_grids()
println("Available grids: ", join(available[1:5], ", "), "...")

# Load a specific grid
grid = load_grid_from_csv("us_state_grid1")
```

### Common US State Grids

Several US state grid layouts are commonly used:

- `us_state_grid1`: Standard US state layout with Alaska and Hawaii positioned in the lower left
- `us_state_grid2`: Alternative arrangement with different positioning for western states
- `us_state_grid3`: Compact layout optimizing for space efficiency
- `us_state_contiguous_grid1`: Contiguous US states only (excludes Alaska and Hawaii)

### Grid Comparison

| Grid | States | Alaska/Hawaii | Aspect Ratio | Best For |
|------|--------|---------------|--------------|----------|
| `us_state_grid1` | 50 + DC | Lower left | Wide | General use |
| `us_state_grid2` | 50 + DC | Alternative | Medium | Presentations |
| `us_state_grid3` | 50 + DC | Compact | Square | Small figures |
| `us_state_contiguous_grid1` | 48 | Excluded | Wide | Continental focus |

## Creating Custom Grids

### Basic Custom Grid

```julia
# Simple custom grid using GeoGrid constructor
my_grid = GeoGrid(
    ["A", "B", "C", "D"],
    [1, 1, 2, 2],
    [1, 2, 1, 2]
)
```

### Geographic Custom Grid

```julia
# European countries grid with names
europe_grid = GeoGrid(
    ["UK", "FR", "DE", "IT", "ES"],
    [1, 2, 2, 3, 3],
    [1, 1, 2, 2, 1],
    ["United Kingdom", "France", "Germany", "Italy", "Spain"]
)
```

### Programmatic Grid Generation

```julia
function create_rectangular_grid(regions::Vector{String}, ncols::Int)
    nrows = ceil(Int, length(regions) / ncols)
    
    rows = Int[]
    cols = Int[]
    
    for (i, region) in enumerate(regions)
        row = ceil(Int, i / ncols)
        col = mod1(i, ncols)
        push!(rows, row)
        push!(cols, col)
    end
    
    return GeoGrid(regions, rows, cols)
end

# Generate 3-column grid for any regions
regions = ["R1", "R2", "R3", "R4", "R5"]
auto_grid = create_rectangular_grid(regions, 3)
```


## Grid Design Principles

### Geographic Accuracy vs Readability

Balance between maintaining geographic relationships and creating readable layouts:

```julia
# Geographically accurate (may be hard to read)
accurate_grid = GeoGrid(
    ["FL", "GA", "SC", "NC"],
    [4, 3, 2, 1],  # True north-south order
    [1, 1, 1, 1]   # All in same column
)

# Readable compromise (sacrifices some accuracy)
readable_grid = GeoGrid(
    ["FL", "GA", "SC", "NC"],
    [2, 2, 1, 1],  # Compressed vertically
    [1, 2, 1, 2]   # Spread horizontally
)
```

### Handling Special Cases

#### Irregular Geographies

```julia
# Grid with gaps for irregular shapes
irregular_grid = GeoGrid(
    ["AK", "HI", "CA", "OR", "WA"],
    [1, 4, 3, 2, 1],     # Alaska and Hawaii separate
    [1, 1, 2, 2, 2]      # Gaps in layout
)
```

## Grid File Operations

### Saving and Loading

```julia
# Load from package grids
grid = load_grid_from_csv("us_state_grid1")

# Load from custom directory
custom_grid = load_grid_from_csv("my_grid.csv", "/path/to/grids")

# Validate after loading
validate_grid(grid)  # Returns true if valid, throws error if conflicts
```

### Grid Formats

#### CSV Format
```csv
code,name,row,col
CA,California,3,1
OR,Oregon,2,1
WA,Washington,1,1
```

The CSV loader supports various column name conventions:
- `code`, `code_alpha3`, `code_country`, `code_iso_3166_2` for region identifiers
- `name` for display names (optional)
- `row`, `col` for positions (required)
- Additional columns become metadata

## Troubleshooting Grids

### Common Issues

**Duplicate positions:**
```julia
# Problem: Two regions at same position
# Solution: Use validate_grid to check
try
    validate_grid(grid)
    println("Grid is valid")
catch e
    println("Grid validation failed: ", e)
end
```

**Missing regions:**
```julia
# Problem: Data regions not in grid
# Solution: Check which regions are available
data_regions = unique(data.state)
grid_regions = get_regions(grid)
missing = setdiff(data_regions, grid_regions)
println("Missing regions: ", missing)
```

**Sparse grids:**
```julia
# Problem: Grid has many empty spaces
# Solution: Check grid density
max_row, max_col = grid_dimensions(grid)
density = length(grid) / (max_row * max_col)
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

- [Core Functions](core.md) - Main GeoFacetMakie functions
- [Utilities](utilities.md) - Helper functions and utilities
