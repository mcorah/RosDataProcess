using RosDataProcess

ts = range(-2pi, stop=2pi, length=500)

a = TimeSeries(sin, ts)
b = differentiate(a)

#plot(a)
#plot(b)
