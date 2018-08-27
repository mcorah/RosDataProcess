using PyCall
@pyimport yaml
@pyimport rosbag

##################
# Bags and loading
##################

immutable AnnotatedBag
  yaml
  bag
  AnnotatedBag(yaml_name, bag_name) =
    new(load_yaml(yaml_name), load_bag(bag_name))
end

AnnotatedBag(x) = AnnotatedBag("$(x).yaml", "$(x).bag")

function load_yaml(x::AbstractString)
  yaml.load(open(x))
end

function load_bag(x::AbstractString)
  rosbag.Bag(x)
end

get_name(x::AbstractString) = match(r".*\.", x).match[1:end-1]

filter_extension(file_names, extension) =
  filter(x->ismatch(Regex("\\\.$(extension)"), x), file_names)

function load_directory(dir::AbstractString)
  file_names = readdir(dir)
  names = map(get_name, filter_extension(file_names, "bag"))

  map(x->AnnotatedBag("$(dir)/$(x)"), names)
end

import Base.close
close(x::AnnotatedBag) = x.bag[:close]()

##################
# Bag manipulation
##################

get_param(param::AbstractString, bag::AnnotatedBag) = get_param(param, bag.yaml)

function get_param(param::AbstractString, yaml::Dict)
  get_param(split(param, "/"), yaml)
end

function get_param(param::AbstractArray, yaml::Dict)
  if length(param) == 1
    yaml[param[1]]
  else
    get_param(param[2:end], yaml[param[1]])
  end
end

function filter_bags(dict, bags::Array{AnnotatedBag})
  ismatch(bag) = all([x[2] == get_param(x[1], bag) for x in dict])

  filter(ismatch, bags)
end

function get_range(field, bags)
  sort(collect(Set(map(x->get_param(field, x), bags))))
end

function sort_bags(bags, spec)
end

#################
# Time conversion
#################

to_sec(x::PyObject) = x[:to_sec]()
to_sec(x::AbstractArray) = map(to_sec, x)
to_sec(x::TimeSeries) = map_time(to_sec, x)

############################
# Topics and data extraction
############################

function get_topic_names(bag)
  # Got this from: http://wiki.ros.org/rosbag/Cookbook
  # Not sure what this thing is returning
  keys(bag.bag[:get_type_and_topic_info]()[2])
end

# Thin wrapper around the python read_messages function
function read_messages(bag::AnnotatedBag, topics)
  bag.bag[:read_messages](topics=topics)
end


# Read messages from a given topic and bag into a time series according to
# time-stamps in the bag
# TODO: Use header stamps?
function read_topic(topic, bag::AnnotatedBag; accessor = x->x)
  topic_message_time = collect(read_messages(bag, [topic]))

  # Access elements of the tuple
  # Use list comprehensions to infer data types as "map" will pass along the
  # "Any" element type.
  ros_times = [x[3] for x in topic_message_time]
  data = [accessor(x[2]) for x in topic_message_time]

  times = to_sec(normalize_start(ros_times))
  TimeSeries(times, data)
end

# Read messages (see read_topic, above) from multiple bags and possibly
# interpolate into a multi-dimensional time series
function read_topic(topic, bags::AbstractArray{AnnotatedBag}; interpolate=false,
                    kws...)
  trials = map(bags) do bag
    read_topic(topic, bag; kws...)
  end

  if interpolate
    interpolate_args = Dict(x for x in kws if x[1] == :num_samples)
    intersect_interpolate(trials; interpolate_args...)
  else
    trials
  end
end

# Read an abstract time series with published data and time from a single bag
function read_series(time_topic, data_topic, bag::AnnotatedBag;
                    access_time=x->x, access_data=x->x)
  # tuple is (topic, data, time)
  tuples = collect(read_messages(bag, [time_topic, data_topic]))

  time = [access_time(x[2]) for x in tuples if x[1] == time_topic]
  data = [access_data(x[2]) for x in tuples if x[1] == data_topic]

  TimeSeries(time, data)
end

# Read an abstract time series (see read_series, above) from multiple bags and
# possibly intersect into a single multi-dimensional time series
function read_series(time_topic, data_topic, bags::AbstractArray{AnnotatedBag};
                     intersect=false, kws...)
  trials = map(bags) do bag
    read_series(time_topic, data_topic, bag; kws...)
  end

  if intersect
    intersect_series(trials)
  else
    trials
  end
end
