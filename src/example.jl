using PyPlot
include("bag_process.jl")
include("data_process.jl")

bag_directory = "$(homedir())/bagfiles/decentralized_exploration_timing_journal/"
#file_names = readdir(bag_directory)
#bag = AnnotatedBag(get_name("$(bag_directory)$(file_names[1])"))
bags = load_directory(bag_directory)


#filtered_bags = filter_bags(Dict(

fixed = Dict("kinematic_exploration/decentralized_enabled" => true)
dec_bags = filter_bags(fixed, bags)

spec = ["num_robots", "num_decentralized"]

bag = dec_bags[1]

topic_names = get_topic_names(bag)

entropy = read_topic("/kinematic_exploration/entropy_reduction", bag)
entropy = mutate_index(x->to_sec(normalize_timing(x)), entropy)
entropy = map_data(x->x[:data], entropy)

plot(get_index(entropy), get_data(entropy))
