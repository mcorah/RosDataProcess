module RosDataProcess

export TimeSeries, get_data, get_index, interpolate_at_time, interpolate

export AnnotatedBag, load_bag, get_name, filter_extension, load_directory,
  get_param, filter_bags, get_range, sort_bags, get_topic_names, read_topic

include("data_process.jl")
include("bag_process.jl")

end # module
