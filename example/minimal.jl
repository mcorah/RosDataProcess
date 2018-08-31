using RosDataProcess

dx = 0.1
# Test simple time series
a = TimeSeries(1:dx:30, sin.(1:dx:30))
b = TimeSeries(10:dx:40, cos.(10:dx:40))
c = TimeSeries(5:dx:20, tan.(5:dx:20))
series = [a, b, c]
interpolated = intersect_interpolate(series)
