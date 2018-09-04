using RosDataProcess
using PyPlot

dx = 0.01
# Test simple time series
a = TimeSeries(sin, -2pi:dx:6pi)
b = TimeSeries(cos, -3pi:dx:2pi)
c = TimeSeries(atan, -5pi:dx:4pi)
series = [a, b, c]
interpolated = intersect_interpolate(series)

# Optional plots to illustrate the above examples
#figure(); foreach(plot, series)
#figure(); plot(interpolated)
