require 'csv'

require_relative File.join("..","lib","population")
require_relative File.join("..","lib","resource_controller")
require_relative File.join("..","lib","resource_controllers","sharing")
require_relative File.join("..","lib","simulation")

class Simulation

  def initialize(data_dir)
    @data_dir = data_dir
    not_sharing = ResourceController.new
    sharing = ResourceControllerSharing.new
    @populations = []
    @populations << Population.new("MA", not_sharing)
    @populations << Population.new("MA_1", not_sharing, start_at: 1)
    @populations << Population.new("MA_sharing", sharing)
    @populations << Population.new("MA_1_sharing", sharing, start_at: 1)
  end

  def run
    headers = ["day", "susceptible", "infected", "immune", "died", "severely_ill", "icu_beds_available", "died_because_of_no_bed", "excess_mortality", "infected_today", "recovered_today", "died_today", "reaction", "infection_rate"]

    outputs = Array.new(@populations.count) { |index| CSV.open(filename_for(@populations[index]), "wb") }

    outputs.each { |output| output << headers }
    
    (365*2).times do |day|
      @populations.each_with_index do |population, index|
        population.tick(day)
        outputs[index] << [ day, population.susceptible, population.infected.sum, population.immune, population.died, population.severely_ill.sum, population.resource_controller.beds_available(population),population.did_not_get_bed, population.excess_mortality, population.infected_today, population.recovered_today, population.died_today, population.reaction, population.infection_rate ]
      end
    end

    outputs.each { |output| output.close() }
  end

  def filename_for(population)
    File.join(@data_dir, "#{population.name}.csv")
  end
end

sim = Simulation.new("data")
sim.run
puts "Done!"

