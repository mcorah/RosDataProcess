using PyPlot
import PyPlot.plot

# plot one or more time series
function plot(x::TimeSeries; kws...)
  time = get_time(x)
  data = get_data(x)

  n_repeat = vcat(1, collect(size(data))[2:end])
  time_array = repeat(time, outer = n_repeat)

  plot(time_array, data; kws...)
end

function plot_mean(x::TimeSeries; kws...)
  plot(mean(x,2); kws...)
end

# Plot the standard error for a time series as a filled polygon.
function plot_standard_error{D}(x::TimeSeries{D,2}; color="k",
                                alpha=0.2, linewidth=0.0, kws...)
  time = get_time(x)
  data = get_data(x)

  # reverse only handles 1D arrays
  stdes = standard_error(data, 2)[:]
  means = mean(data, 2)[:]

  xs = vcat(time, reverse(time))
  ys = vcat(means+stdes, reverse(means-stdes))
  print(size(xs))
  print(size(ys))

  fill(xs, ys; color=color, alpha=alpha, linewidth=linewidth, kws...)
end

# Often, it is to have a single compact plot method for a set of trials
function plot_trials(x::TimeSeries; mean=false, standard_error=false,
                     trials=false, kws...)
  if trials
    plot(x; linestyle=":", kws...)
  end

  if mean
    plot_mean(x; kws...)
  end

  if standard_error
    plot_standard_error(x; kws...)
  end
end
