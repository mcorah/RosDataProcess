using PyPlot
using RosDataProcess

bag_directory = "$(homedir())/bagfiles/decentralized_exploration_timing_journal/"
#file_names = readdir(bag_directory)
bags = load_directory(bag_directory)

fixed = Dict("kinematic_exploration/decentralized_enabled" => false)
dec_bags = filter_bags(fixed, bags)

#spec = ["num_robots", "kinematic_exploration/num_decentralized_planning_rounds"]

bag = dec_bags[1]

# show topics
println("Topic names:")
map(println, get_topic_names(bag))

entropy = read_topic("/kinematic_exploration/entropy_reduction", dec_bags;
                     accessor = x->x[:data], interpolate = true)

plot(entropy, color = "b")
