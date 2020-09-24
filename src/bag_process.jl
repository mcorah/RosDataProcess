##################
# Bags and loading
##################

struct AnnotatedBag
  yaml
  bag
end

function AnnotatedBag(x::AbstractString; preprocess=true)
  yaml_data = load_yaml_data(x, preprocess=preprocess)
  bag_data = load_bag(x * ".bag")

  AnnotatedBag(yaml_data, bag_data)
end

function load_yaml(x::AbstractString)
  yaml.load(open(x))
end

# Load a yaml file. Optionally, save/load the preprocessed yaml file.
function load_yaml_data(x::AbstractString; preprocess=true)
  yaml_file = x * ".yaml"
  jld2_file = x * ".jld2"

  if !preprocess
    data = load_yaml(yaml_file)
  elseif !isfile(jld2_file)
    data = load_yaml(yaml_file)
    @save jld2_file data
  else
    @load jld2_file data
  end

  data
end

function load_bag(x::AbstractString)
  rosbag.Bag(x)
end

get_name(x::AbstractString) = match(r".*\.", x).match[1:end-1]

filter_extension(file_names, extension) =
  filter(x->occursin(Regex("\\.$(extension)\$"), x), file_names)

function get_bag_names(dir)
  file_names = readdir(dir)

  map(get_name, filter_extension(file_names, "bag"))
end

function load_directory(dirs::Array; kwargs...)
  vcat(map(x->load_directory(x, kwargs...), dirs)...)
end
function load_directory(dir::AbstractString; preprocess=true)
  file_names = readdir(dir)
  names = get_bag_names(dir)

  map(x->AnnotatedBag("$(dir)/$(x)", preprocess=preprocess), names)
end

import Base.close
close(x::AnnotatedBag) = x.bag.close()

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

to_sec(x::PyObject) = x.to_sec()
to_sec(x::AbstractArray) = map(to_sec, x)
to_sec(x::TimeSeries) = map_time(to_sec, x)

############################
# Topics and data extraction
############################

function get_topic_names(bag)
  # Got this from: http://wiki.ros.org/rosbag/Cookbook
  # Not sure what this thing is returning
  collect(keys(bag.bag.get_type_and_topic_info()[2]))
end

# Thin wrapper around the python read_messages function
function read_messages(bag::AnnotatedBag, topics)
  bag.bag.read_messages(topics=topics)
end


# Read messages from a given topic and bag into a time series according to
# time-stamps in the bag
# TODO: Use header stamps?
function read_topic(topic::String, bag::AnnotatedBag; accessor = x->x,
                    normalize_start_time=true)
  topic_message_time = collect(read_messages(bag, [topic]))

  # Access elements of the tuple
  # Use list comprehensions to infer data types as "map" will pass along the
  # "Any" element type.
  ros_times = [x[3] for x in topic_message_time]
  data = [accessor(x[2]) for x in topic_message_time]

  if normalize_start_time
    times = to_sec(normalize_start(ros_times))
  else
    times = to_sec(ros_times)
  end

  TimeSeries(times, data)
end

# Read messages (see read_topic, above) from multiple bags and possibly
# interpolate into a multi-dimensional time series
function read_topic(topic::String, bags::AbstractArray{AnnotatedBag}; interpolate=false,
                    num_samples=default_num_samples, kws...)
  trials = map(bags) do bag
    read_topic(topic, bag; kws...)
  end

  if interpolate
    intersect_interpolate(trials; num_samples=num_samples)
  else
    trials
  end
end
# Return an array containing all matching topics
function read_topic(topic::Regex, bags; kws...)
  bag = first_bag(bags)
  topics = get_topic_names(bag)

  matches = filter(x->occursin(topic, x), topics)

  map(matches) do match
    read_topic(match, bags; kws...)
  end
end

# Read an abstract time series with published data and time from a single bag
function read_series(time_topic, data_topic::String, bag::AnnotatedBag;
                    access_time=x->x, access_data=x->x,
                    ignore_timing_mismatch=false
                   )
  time = read_topic(time_topic, bag, accessor=access_time,
                    normalize_start_time=false)
  data = read_topic(data_topic, bag, accessor=access_data,
                    normalize_start_time=false)

  synced_data = map(t->get_at_nearest_time(t, data), get_time(time))

  TimeSeries(get_data(time), synced_data)
end

# Read an abstract time series (see read_series, above) from multiple bags and
# possibly intersect into a single multi-dimensional time series
function read_series(time_topic, data_topic::String,
                     bags::AbstractArray{AnnotatedBag}; intersect=false, kws...)
  trials = map(bags) do bag
    read_series(time_topic, data_topic, bag; kws...)
  end

  if intersect
    intersect_series(trials)
  else
    trials
  end
end

# Return an array containing all matching topics
first_bag(bags::AbstractArray{AnnotatedBag}) = first(bags)
first_bag(bag::AnnotatedBag) = bag
function read_series(time_topic, data_topic::Regex, bags;
                     kws...)
  bag = first_bag(bags)
  topics = get_topic_names(bag)

  matches = filter(x->occursin(data_topic, x), topics)

  map(matches) do match
    read_series(time_topic, match, bags; kws...)
  end
end
