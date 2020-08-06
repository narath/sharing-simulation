require_relative File.join("..","lib","simulations","simulation_sharing")

sim = SimulationSharing.new("data", states:2, offset_days_up_to:100, save_details: true)
sim.run
puts "Done!"


