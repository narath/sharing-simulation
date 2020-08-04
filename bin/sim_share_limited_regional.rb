require_relative File.join("..","lib","simulations","simulation_limited_sharing")

sim = SimulationLimitedSharing.new("data/limited",states:5)
sim.run
puts "Done!"
