require_relative File.join("..","lib","simulations","simulation_sharing")

sim = SimulationSharing.new("data", states: 50)
sim.run
puts "Done!"

