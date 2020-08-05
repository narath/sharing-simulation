require_relative File.join("..","lib","simulations","simulation_sharing")

sim = SimulationSharing.new("data", states:10)
sim.run
puts "Done!"

