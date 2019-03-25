# Profile data processing. Skip plotting for now.

using RosDataProcess
using ProfileView
Profile.init(100000000, 0.001)

function profile_fun()
  println("Entering profiling code")

  bag_directory = "$(homedir())/bagfiles/decentralized_exploration_journal/"
  bags = load_directory(bag_directory)

  # show topics
  println("Topic names:")
  foreach(println, get_topic_names(bags[1]))

  params = Dict(:num_robots => "num_robots",
                :num_decentralized =>
                "kinematic_exploration/num_decentralized_planning_rounds")

  ranges = Dict(key => get_range(value, bags) for (key, value) in params)
  for num_robots = ranges[:num_robots][1:1]
    for (ii, num_decentralized) = enumerate(ranges[:num_decentralized][1:1])
      fixed = Dict(params[:num_robots] => num_robots,
                   params[:num_decentralized] => num_decentralized)
      trials = filter_bags(fixed, bags)

      entropy = read_series("/kinematic_exploration/iteration",
                            "/kinematic_exploration/entropy_reduction", trials;
                            access_data=x->x.data,
                            access_time=x-> num_robots * x.data,
                            intersect=true)
    end
  end

  foreach(close, bags)

  nothing
end

profile_fun()

@profile foreach(1:3) do _
  @time profile_fun()
end

ProfileView.view()
