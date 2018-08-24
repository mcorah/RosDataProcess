using PyPlot
import PyPlot.plot

function plot(x::TimeSeries, args...; kws...)
  time = get_time(x)
  data = get_data(x)

  n_repeat = vcat(1, collect(size(data)))
  time_array = repeat(time, outer = n_repeat)

  plot(time_array, data, args...; kws...)
end
