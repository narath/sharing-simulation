# Ruby simple simulation of COVID
require_relative File.join("..","lib","simulation")

# sim = Simulation.new("data/sirs_slow_reaction_time.csv", reaction_time_to_distance: 7, reaction_time_to_reopen: 7)

sim = Simulation.new("data/sirs_stricter_relaxing.csv", relax_when_new_daily_infections_is_less_than: RELAX_WHEN_NEW_DAILY_INFECTIONS_IS_LESS_THAN/2)
sim.run
puts "Done"


