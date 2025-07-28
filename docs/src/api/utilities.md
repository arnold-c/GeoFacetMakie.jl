# Utilities

This page documents utility functions and helper tools in GeoFacetMakie.jl for data preparation, validation, and workflow optimization.

## Axis Management

```@docs
has_neighbor_left
has_neighbor_right
has_neighbor_above
has_neighbor_below
```

#### `create_axis_kwargs(; base_kwargs, overrides)`

Create axis kwargs with inheritance and overrides.

```julia
# Base styling with specific overrides
base = (fontsize = 12, titlecolor = :black)
specific = create_axis_kwargs(
    base_kwargs = base,
    overrides = (titlecolor = :red,)  # Override for specific axis
)
```
