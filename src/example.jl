using PyPlot
using RosDataProcess

println("Loading bag directory")
bag_directory = "$(homedir())/bagfiles/decentralized_exploration_journal/"
#file_names = readdir(bag_directory)
bags = load_directory(bag_directory)

println("Filtering bags")
fixed = Dict("kinematic_exploration/decentralized_enabled" => false,
             "num_robots" => 16)
dec_bags = filter_bags(fixed, bags)

bag = dec_bags[1]

# show topics
println("Topic names:")
map(println, get_topic_names(bag))

println("Reading bags")
entropy = read_topic("/kinematic_exploration/entropy_reduction", dec_bags;
                     accessor = x->x[:data], interpolate = true)

println("Plotting data")
plots = plot_trials(entropy, mean=true, standard_error=true, trials=false,
                    color="k")
legend(plots[:mean], ["\$n_r=16\$"])
