# Separated Documentation System for GeoFacetMakie.jl

This directory contains the separated documentation system for GeoFacetMakie.jl, which allows you to keep your source code clean and navigable while maintaining comprehensive documentation.

## Structure

The documentation is organized into separate files by functionality:

- `types_docs.jl` - Documentation for `GridEntry` and `GeoGrid` types and constructors
- `grid_operations_docs.jl` - Documentation for grid utility functions
- `grid_loader_docs.jl` - Documentation for CSV grid loading functions
- `geofacet_docs.jl` - Documentation for the main `geofacet` function
- `internal_docs.jl` - Documentation for internal functions (prefixed with `_`)

## How It Works

The system uses Julia's `@doc` macro to attach documentation strings to functions after they are defined. This approach:

1. **Keeps source code clean** - Function definitions are not cluttered with long docstrings
2. **Maintains full documentation** - All functions remain fully documented and accessible via `?function_name`
3. **Preserves functionality** - The Julia help system works exactly as before
4. **Enables better navigation** - Source files are easier to read and understand

## Usage

### For Users
Nothing changes! You can still access documentation normally:

```julia
julia> using GeoFacetMakie
julia> ?GridEntry
julia> ?geofacet
julia> ?grid_dimensions
```

### For Developers

When adding new functions:

1. **Define the function** in the appropriate source file without a docstring
2. **Add documentation** in the corresponding `docs/*.jl` file using the `@doc` macro:

```julia
@doc """
    my_new_function(arg1, arg2)

Description of what the function does.

# Arguments
- `arg1`: Description of first argument
- `arg2`: Description of second argument

# Examples
```julia
result = my_new_function("hello", 42)
```
""" my_new_function
```

3. **Include the docs file** in `src/GeoFacetMakie.jl` if it's a new file

## Benefits

- **Improved code readability** - Source files focus on implementation
- **Better maintainability** - Documentation is organized and easier to update
- **Consistent formatting** - All documentation follows the same patterns
- **Preserved functionality** - All existing tools and workflows continue to work
- **Easier navigation** - Developers can quickly understand code structure

## File Organization

```
src/docs/
├── README.md                 # This file
├── types_docs.jl            # GridEntry, GeoGrid documentation
├── grid_operations_docs.jl  # Grid utility functions
├── grid_loader_docs.jl      # CSV loading functions
├── geofacet_docs.jl         # Main plotting function
└── internal_docs.jl         # Internal helper functions
```

This system provides the best of both worlds: clean, navigable source code and comprehensive, accessible documentation.
