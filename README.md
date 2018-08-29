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

## Examples

* `example/minimal.jl`: Some minimal examples of usage of `TimeSeries`
* `example/abstract_time.jl`: Reproduces several of the plots from the AURO18
  paper for kinematic exploration with separate abstract iterations
