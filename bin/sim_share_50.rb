require_relative File.join("..","lib","simulations","simulation_50_states")

sim = Simulation50States.new("data")
sim.run
puts "Done!"

