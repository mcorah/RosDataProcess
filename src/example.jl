# This script parses and plots abstract time series from a ROS bag where
# messages are associated with an iteration number rather than in real time.
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
bag_directory = "$(homedir())/bagfiles/decentralized_exploration_journal/"
bags = load_directory(bag_directory)

# show topics
println("Topic names:")
foreach(println, get_topic_names(bags[1]))

params = Dict(:num_robots => "num_robots",
              :num_decentralized =>
              "kinematic_exploration/num_decentralized_planning_rounds")

ranges = map(x -> x[1] => get_range(x[2], bags), params)

for num_robots = ranges[:num_robots]
  figure()

  for (ii, num_decentralized) = enumerate(ranges[:num_decentralized])
    println("Plotting trials:"
            * " num_robots=$(num_robots)"
            * " num_decentralized=$(num_decentralized)")

    println("  Filtering")
    fixed = Dict(params[:num_robots] => num_robots,
                 params[:num_decentralized] => num_decentralized)
    trials = filter_bags(fixed, bags)

    println("  Reading bags")
    entropy = read_series("/kinematic_exploration/iteration",
                          "/kinematic_exploration/entropy_reduction", trials;
                          access_data=x->x[:data],
                          access_time=x-> num_robots * x[:data],
                          intersect=true)

    println("  Plotting data")
    plots = plot_trials(entropy, mean=true, standard_error=true,
                        trials=false, color=colors[ii])

    legend_string(n) = (n == 0 ? "G" : "D\$_$(n)\$")
    plots[:mean][1][:set_label](legend_string(num_decentralized))
  end

  title("Entropy reduction: $(num_robots) robots")
  xlabel("Robot-Iteration")
  ylabel("Objective (bits)")
  legend(loc="lower right")

  if save_output
    save_latex("./fig", "entropy_reduction_$(num_robots)")
  end
end
