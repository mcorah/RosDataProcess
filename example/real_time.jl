# This script parses and plots a real time series from a ROS bag where.
# Bags are loaded from a given directory and *should be paired with yaml files
# of the same name.* This script then parses the yaml files to identify ranges
# of values for given params and succinctly selects and processes sets of
# repeated trials.

using PyPlot
using RosDataProcess

# Configuration
save_output = false
colors = generate_colors(10)

println("Loading bag directory")
bag_directory = "$(homedir())/bagfiles/dynamic_exploration_journal/"
bags = load_directory(bag_directory)

# show topics
println("Topic names:")
foreach(println, get_topic_names(bags[1]))

params = Dict(:num_decentralized =>
              "dynamic_exploration/num_decentralized_planning_rounds")

ranges = Dict(key => get_range(value, bags) for (key, value) in params)

# Plot entropy results.
figure()
for (ii, num_decentralized) = enumerate(ranges[:num_decentralized])
  println("Plotting trials:"
          * " num_decentralized=$(num_decentralized)")

  println("  Filtering")
  fixed = Dict(params[:num_decentralized] => num_decentralized)
  trials = filter_bags(fixed, bags)

  println("  Reading bags")
  entropy = read_topic("/entropy", trials; accessor=x->x[:data],
                       interpolate=true)

  println("  Plotting data")
  plots = plot_trials(entropy, mean=true, standard_error=true,
                      trials=false, color=colors[ii])

  legend_string(n) = (n == 0 ? "G" : "D\$_$(n)\$")
  plots[:mean][1][:set_label](legend_string(num_decentralized))
end

title("Entropy reduction: dynamic exploration")
xlabel("Time (s)")
ylabel("Objective (bits)")
legend(loc="lower right")

if save_output
  save_latex("./fig", "dynamic_entropy_reduction")
end

foreach(close, bags)
