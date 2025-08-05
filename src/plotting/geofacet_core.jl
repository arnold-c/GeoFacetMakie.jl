"""
Main geofacet plotting functionality for GeoFacetMakie.jl
"""

using DataFrames
using Makie

export geofacet

function geofacet(
        data::D,
        region_col::R,
        plot_func;
        grid = us_state_grid1,
        link_axes = :none,
        hide_inner_decorations = true,
        title = "",
        titlekwargs = NamedTuple[],
        figure_kwargs = NamedTuple(),
        common_axis_kwargs = NamedTuple(),
        axis_kwargs_list = NamedTuple[],
        legend_kwargs = NamedTuple(),
        func_kwargs = (missing_regions = :skip,),
        additional_regions = :error
    ) where {D <: AbstractDataFrame, R <: Union{<:AbstractString, <:Symbol}}

    # Input validation
    if isempty(data)
        throw(ArgumentError("Data cannot be empty"))
    end

    # Convert region_col to Symbol if it's a string
    region_col_sym = region_col isa String ? Symbol(region_col) : region_col

    if !hasproperty(data, region_col_sym)
        throw(ArgumentError("Column $region_col not found in data"))
    end

    # Validate link_axes parameter
    if !(link_axes in [:none, :x, :y, :both])
        throw(ArgumentError("link_axes must be one of :none, :x, :y, :both"))
    end

    # Validate missing_regions parameter
    if !haskey(func_kwargs, :missing_regions) || !(func_kwargs[:missing_regions] in [:skip, :empty, :error])
        throw(ArgumentError("kwarg `func_kwargs` must contain a value for `missing_regions` equal to one of :skip, :empty, :error"))
    end

    # Validate missing_regions parameter
    if !(additional_regions in [:warn, :error])
        throw(ArgumentError("additional_regions must be one of :warn, :error"))
    end


    # Validate axis_kwargs_list parameter
    if !isa(axis_kwargs_list, Vector{<:NamedTuple})
        throw(ArgumentError("axis_kwargs_list must be a Vector of NamedTuples"))
    end

    # Group data by region column using GroupedDataFrame directly
    grouped_data = _prepare_grouped_data(data, region_col_sym)
    available_regions = _get_available_regions(grouped_data, region_col_sym)

    # Get grid dimensions
    max_row, max_col = grid_dimensions(grid)

    # Create figure with appropriate size
    default_figure_kwargs = (size = (max_col * 200, max_row * 150),)
    merged_figure_kwargs = merge(default_figure_kwargs, figure_kwargs)
    fig = Figure(; merged_figure_kwargs...)

    # Create main grid layout
    grid_layout = fig[1, 1] = GridLayout()

    # Track regions with data for return structure (backward compatibility)
    created_gridlayouts = Dict{String, GridLayout}()

    grid_regions = Set(grid.region)
    data_regions = Set(string.(data[!, region_col_sym]))
    n_data_regions = length(data_regions)

    if length(unique(data_regions)) != n_data_regions
        error("The number of unicode regions must be the same as the total number present in the data.\nInstead, recieved $n_data_regions, but $(length(unique(data_regions))) unique ones")
    end

    # Handle missing regions check
    if func_kwargs[:missing_regions] == :error
        missing_from_data = setdiff(grid_regions, data_regions)
        if !isempty(missing_from_data)
            missing_list = join(missing_from_data, ", ")
            throw(ArgumentError("Missing regions in data: $missing_list"))
        end
    end

    # Handle additional regions check
    extra_from_data = setdiff(data_regions, grid_regions)
    if !isempty(extra_from_data)
        extra_list = join(extra_from_data, ", ")
        extra_message = "Additional regions in data not present in the grid provided: $extra_list"
        if additional_regions == :error
            throw(ArgumentError(extra_message))
        else
            @warn extra_message
        end
    end

    # Choose which grid to use for neighbor detection based on missing_regions setting
    # When missing_regions = :empty, empty axes are created so use full grid
    # When missing_regions = :skip, only data positions have axes so use data-only grid
    neighbor_detection_grid = if func_kwargs[:missing_regions] == :empty
        grid  # Use full grid since empty axes will be created
    else
        # Create a filtered grid containing only positions that have data
        # This is used for neighbor detection to ensure axis decorations are only hidden
        # when there are actual neighboring plots with data
        data_entries = GridEntry[]
        for entry in grid
            if _has_region_data(available_regions, entry.region)
                push!(data_entries, entry)
            end
        end
        StructArray(data_entries)
    end

    # Create axes for all grid positions
    for entry in grid
        region_code, row, col = entry
        # Create axis at grid position
        gl = GridLayout(grid_layout[row, col])
        created_gridlayouts[region_code] = gl

        # Use number of axes from axis_kwargs_list, default to 1 if empty
        num_axes = isempty(axis_kwargs_list) ? 1 : length(axis_kwargs_list)

        # Calculate per-axis decoration hiding kwargs based on neighbor detection and axis linking
        per_axis_decoration_kwargs = NamedTuple[]

        for i in 1:num_axes
            axis_decoration_kwargs = NamedTuple()

            if hide_inner_decorations
                # Only hide x-axis decorations if x-axes are linked AND there's a neighbor below
                if (link_axes == :x || link_axes == :both) && has_neighbor_below(neighbor_detection_grid, region_code)
                    axis_decoration_kwargs = merge(
                        axis_decoration_kwargs, (
                            xticksvisible = false,
                            xticklabelsvisible = false,
                            xlabelvisible = false,
                        )
                    )
                end

                # For y-axis decorations, check ylabel position for this specific axis
                if (link_axes == :y || link_axes == :both)
                    # First merge common and per-axis kwargs to determine ylabel position
                    temp_kwargs = common_axis_kwargs
                    if i <= length(axis_kwargs_list)
                        temp_kwargs = merge(temp_kwargs, axis_kwargs_list[i])
                    end

                    yaxis_position = _get_yaxis_position(temp_kwargs)

                    # Check appropriate neighbor based on ylabel position
                    should_hide_y = if yaxis_position == :right
                        has_neighbor_right(neighbor_detection_grid, region_code)
                    else  # :left (default)
                        has_neighbor_left(neighbor_detection_grid, region_code)
                    end

                    if should_hide_y
                        axis_decoration_kwargs = merge(
                            axis_decoration_kwargs, (
                                yticksvisible = false,
                                yticklabelsvisible = false,
                                ylabelvisible = false,
                            )
                        )
                    end
                end
            end

            push!(per_axis_decoration_kwargs, axis_decoration_kwargs)
        end

        # Merge all kwargs for this region's axes
        processed_axis_kwargs_list = _merge_axis_kwargs(
            common_axis_kwargs,
            axis_kwargs_list,
            per_axis_decoration_kwargs,
            num_axes
        )

        # Check if we have data for this region
        if _has_region_data(available_regions, region_code)
            # Get the actual data for this region
            region_data = _get_region_data(grouped_data, region_col_sym, region_code)

            # Execute plot function with error handling
            try
                # For convenience: if only one set of kwargs, try passing them directly first
                # This allows simpler function signatures for single-axis plots
                if length(processed_axis_kwargs_list) == 1
                    try
                        plot_func(gl, region_data; func_kwargs..., processed_axis_kwargs_list[1]...)
                    catch e
                        # If that fails, try the explicit API (for backwards compatibility)
                        if e isa UndefKeywordError && e.var == :processed_axis_kwargs_list
                            plot_func(gl, region_data; func_kwargs..., processed_axis_kwargs_list = processed_axis_kwargs_list)
                        else
                            rethrow()
                        end
                    end
                else
                    plot_func(gl, region_data; func_kwargs..., processed_axis_kwargs_list = processed_axis_kwargs_list)
                end
            catch e
                if occursin(r"InvalidAttributeError\(Axis, .*missing_regions", "$e")
                    error("Make sure to include `missing_regions` as a kwarg in your plotting function definition!")
                end
                error("Error plotting region $region_code: $e")
            end
        elseif func_kwargs[:missing_regions] == :empty
            # No data for this region
            # Create empty axis with region label
            # Need to pass all items in processed_axis_kwargs_list to Axis to
            # Correctly handle hiding decorations for empty facets
            for processed_axis_kwargs in processed_axis_kwargs_list
                ax = Axis(gl[1, 1]; title = region_code, processed_axis_kwargs...)
            end
        elseif func_kwargs[:missing_regions] == :skip
            continue
        else
            error("Region $region_code does not contain any data and `func_kwargs = (missing_regions = :error, ...)`\nTo proceed with the current data and grid, change the `missing_regions` kwarg value to one of :empty or :skip")
        end
    end

    # Apply axis linking
    if link_axes != :none && !isempty(created_gridlayouts)
        gl_list = collect(values(created_gridlayouts))
        axes_by_position = collect_gl_axes_by_position(gl_list)

        # Link each position's axes separately
        for position_axes in axes_by_position
            if !isempty(position_axes)
                if link_axes == :x
                    linkxaxes!(position_axes...)
                elseif link_axes == :y
                    linkyaxes!(position_axes...)
                elseif link_axes == :both
                    linkxaxes!(position_axes...)
                    linkyaxes!(position_axes...)
                end
            end
        end
    end

    if title != ""
        Label(grid_layout[0, :], title; titlekwargs...)
    end

    # Create legend only if requested and labeled plots exist
    if !isempty(legend_kwargs)
        legend_title = ""
        legend_kwargs_dict = Dict(pairs(legend_kwargs))
        if haskey(legend_kwargs, :title)
            legend_title = legend_kwargs[:title]
            delete!(legend_kwargs_dict, :title)
        end

        nrows = maximum(grid.row)
        ncols = maximum(grid.col)
        legend_col = ncols + 1
        legend_row = 1:nrows

        if haskey(legend_kwargs, :legend_position)
            legend_position_nt = legend_kwargs[:legend_position]
            @assert typeof(legend_position_nt) <: Tuple
            if !isnothing(legend_position_nt[1])
                legend_row = legend_position_nt[1]
            end
            if !isnothing(legend_position_nt[2])
                legend_col = legend_position_nt[2]
            end
            delete!(legend_kwargs_dict, :legend_position)
        end

        # Check if any axes have labeled plots
        has_labeled_plots = _has_labeled_plots(fig)

        if has_labeled_plots
            Legend(grid_layout[legend_row, legend_col], fig.content[1], legend_title; legend_kwargs_dict...)

            if maximum(legend_row) <= nrows
                # Don't set to 100% otherwise axis labels can be clipped by bounding box
                map(lr -> rowsize!(grid_layout, lr, Relative(0.98 / nrows)), 1:nrows)
            end
            if maximum(legend_col) <= ncols
                # Don't set to 100% otherwise axis labels can be clipped by bounding box
                map(lc -> colsize!(grid_layout, lc, Relative(0.98 / ncols)), 1:ncols)
            end
        else
            @warn "Legend requested but no plots with labels found. Add labels to your plots using `label=\"My Label\"` parameter in plotting functions."
        end
    end

    return fig
end
