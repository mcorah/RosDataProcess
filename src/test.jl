using RosDataProcess

# Test simple time series
a = TimeSeries(1:30, sin(1:30))
b = TimeSeries(10:40, cos(10:40))
c = TimeSeries(5:20, tan(5:20))
series = [a, b, c]
interpolated = intersect_interpolate(series, 10)
