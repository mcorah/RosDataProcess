module RosDataProcess

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
get_topic_names, read_topic

include("bag_process.jl")

end # module
