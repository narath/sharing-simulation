require 'csv'
require 'ruby-progressbar'

require_relative File.join("..","lib","population")
require_relative File.join("..","lib","resource_controller")
require_relative File.join("..","lib","resource_controllers","sharing")
require_relative File.join("..","lib","simulation")

class Scenario
  attr_accessor :name
  attr_reader :resources, :populations

  def initialize(name, resources=nil)
    @name = name
    @resources = resources
    @populations = []
    yield self, @populations if block_given?
  end

end

class Simulation

  def initialize(data_dir)
    @data_dir = data_dir
    @scenarios = []

    # a collection of independent states not sharing
    # start_dates do not matter
    @scenarios << Scenario.new("not sharing", ResourceController.new) do |scenario|
      50.times do |n_state|
        scenario.populations << Population.new("s#{n_state}", scenario.resources)
      end
    end

    # a collection of 2 states that are sharing
    # we create a series of combinations in which the start date of the pandemic is different
    @scenarios << Scenario.new("sharing") do |scenario|
      25.times do |n|
        scenario.populations << Scenario.new("sharing-#{n}", ResourceControllerSharing.new) do |scenario|
          5.times do |n_state|
            scenario.populations << Population.new("s#{n_state}", scenario.resources, start_at: n_state*n)
          end
        end
      end
    end 
  end

  def run
    # headers = ["day", "susceptible", "infected", "immune", "died", "severely_ill", "icu_beds_available", "died_because_of_no_bed", "excess_mortality", "infected_today", "recovered_today", "died_today", "reaction", "infection_rate"]

    # each_population do |scenario_name, population|
    #   population.output = CSV.open(filename_for(scenario_name, population), "wb")
    #   population.output << headers
    # end
    
    days = 365*5
    progress = ProgressBar.create(total: days)
    days.times do |day|
      each_population do |scenario_name, population|
        population.tick(day)
        # population.output << [ day, population.susceptible, population.infected.sum, population.immune, population.died, population.severely_ill.sum, population.resource_controller.beds_available(population),population.did_not_get_bed, population.excess_mortality, population.infected_today, population.recovered_today, population.died_today, population.reaction, population.infection_rate ]
      end
      progress.increment
    end

    # each_population do |scenario_name, population|
    #   population.output.close()
    #   population.output = nil
    # end

    # @scenarios.each do |scenario|
    #   puts "scenario #{scenario.name}"
    #   data = []
    #   scenario.populations.each do |p|
    #     if p.is_a?(Population)
    #       data << [p.start_at, p.resource_controller.name, p.died]
    #     elsif p.is_a?(Scenario)
    #       puts " -- #{p.name}"
    #       p.populations.each do |p2|
    #           data << [p2.start_at, p2.resource_controller.name, p2.died]
    #       end
    #     end
    #   end
    #   puts data.inspect
    # end

    # now summarize the difference between the populations
    # export the not sharing scenario
    with_scenario "not sharing" do |s|
      CSV.open(File.join(@data_dir, "summary-not_sharing.csv"), "wb") do |csv|
        csv << ["State", "Died"]
        s.populations.each do |p|
          csv << [p.name, p.died]
        end
      end 
    end

    with_scenario "sharing" do |s|
      CSV.open(File.join(@data_dir, "summary-sharing-5states.csv"), "wb") do |csv|
        header = []
        has_written_header = false

        s.populations.each do |sub|
          output = []
          header << "offset"
          output << sub.populations[1].start_at

          sub.populations.each_with_index do |sub_pop,index|
            header << index
            output << sub_pop.died
          end

          if !has_written_header
            csv << header
            has_written_header = true
          end
          csv << output
        end
      end
    end
  end

  def filename_for(scenario, population)
    File.join(@data_dir, "#{scenario}-#{population.name}.csv")
  end

  def each_population
    @scenarios.each do |scenario|
      scenario.populations.each do |population|
        if population.is_a?(Population)
          yield scenario.name, population
        elsif population.is_a?(Scenario)
          name = "#{scenario.name}-#{population.name}"
          population.populations.each do |p2|
            yield name, p2
          end
        end
      end
    end
  end

  def with_scenario(name)
   s = @scenarios.find {|s| s.name == name}
   if block_given?
    yield s
   else
     s
   end
  end

end

sim = Simulation.new("data")
sim.run
puts "Done!"

