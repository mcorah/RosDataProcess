# RosDataProcess

This package is a monolith for managing and processing data from ROS bags with
emphasis on plotting multiples of experiments with multiple trials.
The design tries to infer what can be inferred, make features appropriately
configurable, and avoid clutter.

The main features that have been implemented so far are:
* Handling of time-series data via a `TimeSeries` type that behaves like an
  array but carries a special time-parametrization for the first dimension
* A small set of tools for processing time series especially for resampling,
  aligning, and processing sets of trials
* Tools for managing and reading collections of ROS-bags and for processing
  associated `yaml` files
* A few tools for plotting time series

## Setup
This package relies on the `rosbag` python package which does not seem to be
available on Conda and is not installed for Python3 on my machine either.
To deal with this, you will wan to set `PyCall` to use your local installation
of Python2. This will in turn give Julia access to your installation of `rosbag`
that came with ROS
```
ENV["PYTHON"]="<path to your Python2 installation e.g. /usr/bin/python>"
Pkg.add("PyCall")
Pkg.build("PyCall")
```
It seems to also be a good idea to add `PYTHON` to your environment so that
`PyCall` doesn't get built later on with an incorrect version.

## Examples

* `example/minimal.jl`: Some minimal examples of usage of `TimeSeries`
* `example/derivative_example.jl`: Demonstrates computation of the numeric
  derivative of a time series
* `example/select_times_example.jl`: Demonstrates the `select_times` method
* `example/abstract_time.jl`: Reproduces several of the plots from the AURO18
  paper for kinematic exploration with separate abstract iterations
* `example/real_time.jl`: Reproduces one of the plots from the AURO18
  paper for dynamic exploration run in real-time (or equivalently ROS-time)
