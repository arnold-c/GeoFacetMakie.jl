# Refactoring Plan for GeoFacetMakie.jl

Based on analysis of the source code and TODO comments, this document outlines a comprehensive plan to eliminate redundancies and simplify the codebase following Kent Beck's "Tidy First" principles.

## Current Redundancies and Issues Identified

### 1. **Overly Complex Data Structures**
- **GeoGrid struct**: The TODO comment in `structs.jl:7` suggests this can be simplified to just a Set, as the name field provides no value
- **Redundant data storage**: Multiple dictionaries storing similar information (`gl_dict`, `data_mapping`)

### 2. **Inefficient Data Processing**
- **Double data storage**: `_group_data_by_region()` creates redundant entries for case-insensitive matching
- **Complex region lookup**: `_find_region_data()` performs multiple case checks that could be simplified
- **Unnecessary data passing**: Functions return full data when only boolean checks are needed

### 3. **Overly Complex Return Values**
- **geofacet function**: Returns multiple values when only the figure is typically needed
- **Intermediate data structures**: Several TODO comments suggest simplifying what's returned

## TODO Comments to Address

From `geofacet.jl`:
- Line 207: `# TODO: update when change function to return gdf`
- Line 222: `# TODO: delete these` (referring to gl_dict and data_mapping)
- Line 227: `# TODO: update when change grid to a Set.`
- Line 258: `# TODO: update when change grid to a Set.`
- Line 326: `# TODO: update when change grouped_data to a gdf.`
- Line 356: `# TODO: update axis linking when delete gl_dict to access directly from figure`
- Line 377: `# TODO: Just return the figure`
- Line 386: `# TODO: Implement just as grouped df. No need to save region codes.`
- Line 408: `# TODO: Update to work with gdf. Should just pass a Set of the unique region codes in the gdf.`

From `structs.jl`:
- Line 7: `# TODO: Delete struct as can just save as a Set. The name isn't providing any value`

## Refactoring Plan (Structural Changes First)

### Phase 1: Structural Simplifications (No Behavior Changes)

#### 1.1 Replace GeoGrid with StructArray
**Current**: Complex struct with validation
```julia
struct GeoGrid
    name::String
    positions::Dict{String, Tuple{Int, Int}}
    # + validation logic
end
```

**Target**: StructArray-based approach for better performance
```julia
using StructArrays

struct GridEntry
    region::String
    row::Int
    col::Int
end

const GeoGrid = StructArray{GridEntry}

# Backward-compatible constructor
function GeoGrid(name::String, positions::Dict{String, Tuple{Int, Int}})
    entries = [GridEntry(region, row, col) for (region, (row, col)) in positions]
    return StructArray(entries)
end
```

**Benefits of StructArray approach**:
- **Memory efficiency**: Structure-of-Arrays (SOA) layout for better cache locality
- **Vectorized operations**: Can apply operations to entire columns efficiently
- **Performance**: Better SIMD optimization and reduced memory overhead
- **Integration**: Natural compatibility with DataFrames.jl and Julia ecosystem

**Files to modify**:
- `src/structs.jl` - Replace struct with StructArray-based definition
- `src/grid_loader.jl` - Update loading functions to return StructArray
- `src/grid_operations.jl` - Update all functions to use StructArray API with vectorized operations
- `src/geofacet.jl` - Update grid usage and iteration patterns
- `Project.toml` - Add StructArrays.jl dependency

#### 1.2 Simplify Data Grouping
**Current**: Custom grouping with case-insensitive dictionary
```julia
function _group_data_by_region(data, region_col)
    # Creates redundant entries for case matching
    result = Dict{String, Any}()
    for group in grouped
        region_code = string(group[1, region_col])
        result[uppercase(region_code)] = group
        result[region_code] = group  # Duplicate storage
    end
    return result
end
```

**Target**: Use DataFrames.jl `GroupedDataFrame` directly
```julia
function _prepare_grouped_data(data, region_col)
    # Standardize region codes once
    data_copy = copy(data)
    data_copy[!, region_col] = uppercase.(string.(data_copy[!, region_col]))
    return groupby(data_copy, region_col)
end
```

#### 1.3 Eliminate Redundant Storage
**Current**: Multiple dictionaries
```julia
gl_dict = Dict{String, GridLayout}()
data_mapping = Dict{String, Any}()
```

**Target**: Access axes directly from figure structure
```julia
# No intermediate storage needed
# Access axes directly from figure when needed
```

#### 1.4 Simplify Function Returns
**Current**: Complex NamedTuple
```julia
return (
    figure = fig,
    gls = gl_dict,
    grid_layout = grid_layout,
    data_mapping = data_mapping,
)
```

**Target**: Return only the Figure object
```julia
return fig
```

### Phase 2: Behavioral Improvements (After Structural Changes)

#### 2.1 Optimize Region Lookup
**Current**: Returns full data
```julia
function _find_region_data(grouped_data, region_code)
    # Multiple case checks, returns data
    if haskey(grouped_data, region_code)
        return grouped_data[region_code]
    end
    # ... more case checking
    return nothing
end
```

**Target**: Return boolean, pass region set
```julia
function _has_region_data(available_regions::Set{String}, region_code::String)
    return uppercase(region_code) in available_regions
end
```

#### 2.2 Streamline Grid Operations
- Update grid operation functions to work with simplified data structure
- Remove unnecessary validation that's now handled elsewhere

## Detailed Implementation Steps

### Step 1: Implement StructArray-based GeoGrid (High Priority)
**Commits**: Structural changes only
1. Add StructArrays.jl dependency to `Project.toml`
2. Define `GridEntry` struct and `GeoGrid` type alias in `structs.jl`
3. Add backward-compatible constructor for existing API
4. Update grid loading functions in `grid_loader.jl` to create StructArrays
5. Update grid operations in `grid_operations.jl` to use StructArray API with vectorized operations
6. Update usage in `geofacet.jl` to work with new iteration patterns
7. Run tests to ensure no behavior changes

### Step 2: Refactor Data Grouping (High Priority)
**Commits**: Structural changes only
1. Replace `_group_data_by_region()` with `_prepare_grouped_data()`
2. Update all callers to use GroupedDataFrame directly
3. Eliminate redundant case-insensitive storage
4. Run tests to ensure no behavior changes

### Step 3: Simplify Region Data Handling (Medium Priority)
**Commits**: Behavioral improvements
1. Change `_find_region_data()` to `_has_region_data()` returning Bool
2. Pass Set of available regions instead of full data
3. Eliminate redundant data passing
4. Update tests and verify performance improvements

### Step 4: Remove Intermediate Storage (Medium Priority)
**Commits**: Structural changes
1. Eliminate `gl_dict` by accessing axes from figure directly
2. Remove `data_mapping` as it's not essential for core functionality
3. Update axis linking to work without `gl_dict`
4. Run tests to ensure functionality preserved

### Step 5: Simplify Return Values (Medium Priority)
**Commits**: API changes
1. Change `geofacet()` to return only Figure
2. Update documentation and examples
3. Consider backward compatibility if needed
4. Update tests

### Step 6: Optimize Grid Operations (Low Priority)
**Commits**: Performance optimization
1. Optimize grid operation functions to leverage StructArray vectorized operations
2. Implement efficient neighbor detection using broadcasting
3. Add performance benchmarks comparing old vs new implementation
4. Update tests to verify performance improvements

### Step 7: Update Tests and Documentation (Low Priority)
**Commits**: Final cleanup
1. Modify tests to work with simplified data structures
2. Ensure all functionality still works correctly
3. Add performance benchmarks to verify improvements
4. Update documentation and examples

## Benefits of This Refactoring

1. **Reduced Memory Usage**: Eliminate redundant data storage
2. **Improved Performance**: Simpler data structures and fewer lookups
3. **Cleaner API**: Simpler return values and function signatures
4. **Better Maintainability**: Less complex code with fewer moving parts
5. **Alignment with Julia Idioms**: Use standard library patterns instead of custom abstractions

## Risk Mitigation

1. **Comprehensive Testing**: Each structural change will be validated with existing tests
2. **Incremental Changes**: One TODO item at a time, ensuring tests pass after each change
3. **Backward Compatibility**: Maintain public API compatibility where possible
4. **Documentation Updates**: Update examples and documentation to reflect changes

## Success Criteria

- All TODO comments addressed
- Tests continue to pass
- No breaking changes to public API (unless explicitly planned)
- Improved performance metrics
- Reduced code complexity
- Cleaner, more maintainable codebase

## Implementation Order

1. **High Priority** (Structural changes with immediate benefits):
   - Replace GeoGrid struct with StructArray-based approach
   - Refactor data grouping to use GroupedDataFrame

2. **Medium Priority** (Behavioral improvements):
   - Simplify region data handling
   - Remove intermediate storage
   - Simplify return values

3. **Low Priority** (Cleanup and optimization):
   - Optimize grid operations with vectorized StructArray operations
   - Update tests and documentation

## StructArray Implementation Details

### Memory Layout Comparison
```julia
# Current: Array of structs (AOS)
# Memory: [region1,row1,col1][region2,row2,col2][region3,row3,col3]...

# StructArray: Structure of arrays (SOA)  
# Memory: [region1,region2,region3...][row1,row2,row3...][col1,col2,col3...]
```

### Performance Advantages
```julia
# Vectorized operations on grid data
regions_in_row_5 = grid.region[grid.row .== 5]
positions_below = grid[grid.row .> 3]
unique_rows = unique(grid.row)

# Easy integration with DataFrames
df = DataFrame(grid)
result = leftjoin(data, DataFrame(grid), on = :region)

# Efficient neighbor detection
function has_neighbor_below(grid::GeoGrid, region::String)
    pos = get_position(grid, region)
    isnothing(pos) && return false
    row, col = pos
    return any((grid.col .== col) .& (grid.row .> row))
end
```

### Backward Compatibility
The StructArray implementation maintains full backward compatibility:
- Same public API for all grid operations
- Constructor compatibility: `GeoGrid(name, positions_dict)` still works
- Iteration compatibility: Can still iterate over grid entries
- Property access: All existing functions return the same types

This plan addresses all identified TODO comments while following the principle of making structural changes first, then behavioral improvements. The StructArray approach provides significant performance and memory benefits through structure-of-arrays layout while maintaining full API compatibility. Each phase can be implemented and tested independently, ensuring the codebase remains stable throughout the refactoring process.