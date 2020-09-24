import PyPlot.plot

################
# Plotting tools
################

# plot one or more time series
function plot(x::TimeSeries; kws...)
  time = get_time(x)
  data = get_data(x)

  n_repeat = vcat(1, collect(size(data))[2:end])
  time_array = repeat(time, outer = n_repeat)

  plot(time_array, data; kws...)
end

function plot_mean(x::TimeSeries; kws...)
  plot(mean(x, dims=2); kws...)
end

# Plot the standard error for a time series as a filled polygon.
function plot_standard_error(x::TimeSeries{<:Any,2}; color="k", alpha=0.2,
                             linewidth=0.0, kws...)
  time = get_time(x)
  data = get_data(x)

  # reverse only handles 1D arrays
  stdes = standard_error(data, 2)[:]
  means = mean(data, dims=2)[:]

  xs = vcat(time, reverse(time))
  ys = vcat(means+stdes, reverse(means-stdes))

  fill(xs, ys; color=color, alpha=alpha, linewidth=linewidth, kws...)
end

# Often, it is to have a single compact plot method for a set of trials
function plot_trials(x::TimeSeries; mean=false, standard_error=false,
                     trials=false, label=Nothing, kws...)
  ret = Dict{Symbol, Any}()

  if trials
    ret[:trials] = plot(x; linestyle=":", kws...)
  end

  if mean
    ret[:mean] = plot_mean(x; label=label, kws...)
  end

  if standard_error
    ret[:standard_error] = plot_standard_error(x; kws...)
  end

  ret
end

###############
# Color schemes
###############

standard_colors = [RGB(0,0,1), RGB(1,0,0), RGB(0,1,0)]

rgb_tuple(color::RGB) = (red(color), green(color), blue(color))

generate_colors(x::AbstractArray) = generate_colors(length(x))
generate_colors(x::Integer) =
  map(rgb_tuple, distinguishable_colors(x, standard_colors))

#############
# File output
#############

# Changes a title to an appropriate file name
to_file_name(s) = replace(lowercase(s), " ", "_")

function save_latex(fig_path, title; kwargs...)
  mkpath(fig_path)

  matplotlib2tikz.save("$(fig_path)/$(title).tex",
                       axis_height="\\figureheight",
                       axis_width="\\figurewidth"; kwargs...)
end
