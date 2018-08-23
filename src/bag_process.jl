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

function read_topic(topic, bag::AnnotatedBag; accessor = x->x)
  topic_message_time = collect(bag.bag[:read_messages](topics=[topic]))

  # access elements of the tuple
  ros_times = map(x->x[3], topic_message_time)
  data = map(x -> accessor(x[2]), topic_message_time)

  times = to_sec(normalize_start(ros_times))
  TimeSeries(times, data)
end
