__precompile__()
module RosDataProcess

using LinearAlgebra, PyCall, PyPlot, Colors, Statistics, JLD2

const matplotlib2tikz = PyNULL()
const yaml = PyNULL()
const rosbag = PyNULL()

function __init__()
  try
    copy!(matplotlib2tikz, pyimport("tikzplotlib"))
  catch e
    println("Could not import tikzplotlib, trying matploblib2tikz instead")
    copy!(matplotlib2tikz, pyimport("matplotlib2tikz"))
  end

  copy!(yaml, pyimport_conda("yaml", "pyyaml"))

  try
    copy!(rosbag, pyimport("rosbag"))
  catch e
    println("Could not import rosbag.")
    println("Bags will not load, but other functions will work.")
  end

end

export TimeSeries, time_type, data_type, time_eltype, get_time, get_data,
mutate_time, mutate_data, map_time, map_data, indices_match

include("time_series.jl")

export normalize_start, intersect_intervals, intersect_regular, interpolate,
get_at_time, intersect_interpolate, intersect_series, select_times,
select_indices, standard_error, differentiate

include("data_process.jl")

export plot, plot_standard_error, plot_mean, plot_mean, plot_trials,
generate_colors, first_horizontal_intersection

include("plotting.jl")

export AnnotatedBag, load_yaml, load_yaml_data, load_bag, get_name,
get_bag_names, filter_extension, load_directory, get_param, filter_bags,
get_range, sort_bags, to_sec, get_topic_names, first_bag, read_topic,
read_series, to_file_name, save_latex

include("bag_process.jl")

end # module
