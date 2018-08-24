using PyPlot
import PyPlot.plot

function plot(x::TimeSeries, args...; kws...)
  time = get_time(x)
  data = get_data(x)

  n_repeat = vcat(1, collect(size(data))[2:end])
  time_array = repeat(time, outer = n_repeat)

  plot(time_array, data, args...; kws...)
end

function plot_mean(x::TimeSeries, args...; kws...)
  plot(mean(x,2), args...; kws...)
end

function plot_standard_error{D}(x::TimeSeries{D,2}, args...; color="k",
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

  fill(xs, ys, args...; color=color, alpha=alpha, linewidth=linewidth, kws...)
end
