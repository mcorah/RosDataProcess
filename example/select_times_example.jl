using RosDataProcess
using PyPlot

ts = range(-10pi, stop=10pi, length=500)

a = TimeSeries(sin, ts)
b = select_times(x -> -2pi <= x <= 2pi, a)

plot(a)
figure()
plot(b)
