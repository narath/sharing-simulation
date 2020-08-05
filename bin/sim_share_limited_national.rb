require_relative File.join("..","lib","simulations","simulation_limited_sharing")

sim = SimulationLimitedSharing.new("data/limited",states:50)
sim.run
puts "Done!"
