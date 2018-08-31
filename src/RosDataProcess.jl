__precompile__()
module RosDataProcess

using LinearAlgebra, PyCall, PyPlot, Colors, Statistics

const matplotlib2tikz = PyNULL()
const yaml = PyNULL()
const rosbag = PyNULL()

function __init__()
  copy!(matplotlib2tikz, pyimport_conda("matplotlib2tikz", "matplotlib2tikz"))
  copy!(yaml, pyimport_conda("yaml", "pyyaml"))
  copy!(rosbag, pyimport("rosbag"))
end

export TimeSeries, time_type, data_type, time_eltype, get_time, get_data,
mutate_time, mutate_data, map_time, map_data, indices_match

include("time_series.jl")

export normalize_start, intersect_intervals, intersect_regular, interpolate,
get_at_time, intersect_interpolate, standard_error

include("data_process.jl")

export plot, plot_standard_error, plot_mean, plot_mean, plot_trials,
generate_colors

include("plotting.jl")

export AnnotatedBag, load_yaml, load_bag, get_name, filter_extension,
load_directory, get_param, filter_bags, get_range, sort_bags, to_sec,
get_topic_names, read_topic, read_series, to_file_name, save_latex

include("bag_process.jl")

end # module
