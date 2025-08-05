# Exported Predefined Grids

All the grids have been sourced from the [grid designer repository](https://github.com/hafen/grid-designer) by Ryan Hafen, that have been created for the [geofacet R package](https://hafen.github.io/geofacet/)

```@example
using GeoFacetMakie
grids = list_available_grids()
println("Available grids:\n\n", join(grids, "\n"))
```
