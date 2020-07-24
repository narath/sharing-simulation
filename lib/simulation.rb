require 'csv'

class Simulation

  def initialize(population, filename)
    @population = population
    @filename = filename
  end

  def run
    CSV.open(@filename, "wb") do |output|

      output << ["day", "susceptible", "infected", "immune", "died", "severely_ill", "icu_beds_available", "died_because_of_no_bed", "excess_mortality", "infected_today", "recovered_today", "died_today", "reaction", "infection_rate"]

      (365*2).times do |day|
        @population.tick(day)
        output << [ day, @population.susceptible, @population.infected.sum, @population.immune, @population.died, @population.severely_ill.sum, @population.icu_beds_available - @population.severely_ill_today, @population.did_not_get_bed, @population.excess_mortality, @population.infected_today, @population.recovered_today, @population.died_today, @population.reaction, @population.infection_rate ]

      end
    end
  end
end


