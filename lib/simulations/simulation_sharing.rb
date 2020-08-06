require 'csv'
require 'ruby-progressbar'

require_relative File.join("..","population")
require_relative File.join("..","resource_controller")
require_relative File.join("..","resource_controllers","sharing")
require_relative File.join("..","scenario")
require_relative File.join("..","simulation_base")

class SimulationSharing < SimulationBase

  def initialize(data_dir, states: 2, offset_days_up_to: 10, save_details: false)
    @data_dir = data_dir
    @states = states
    @offset_days_up_to = offset_days_up_to
    @save_details = save_details
    @scenarios = []

    # a collection of independent states not sharing
    # start_dates do not matter
    @scenarios << Scenario.new("not sharing", ResourceController.new) do |scenario|
      @states.times do |n_state|
        scenario.populations << Population.new("s#{n_state}", scenario.resources)
      end
    end

    # a collection of 2 states that are sharing
    # we create a series of combinations in which the start date of the pandemic is different
    @scenarios << Scenario.new("sharing") do |scenario|
      @offset_days_up_to.times do |n|
        scenario.populations << Scenario.new("sharing-#{n}", ResourceControllerSharing.new) do |scenario|
          @states.times do |n_state|
            scenario.populations << Population.new("s#{n_state}", scenario.resources, start_at: n_state*n)
          end
        end
      end
    end 
  end

  def run
    if @save_details
      headers = ["day", "susceptible", "infected", "immune", "died", "severely_ill", "icu_beds_available", "died_because_of_no_bed", "excess_mortality", "infected_today", "recovered_today", "died_today", "reaction", "infection_rate"]

      each_population do |scenario_name, population|
        population.output = []
        population.output << headers
      end
    end
    
    days = 365*5
    progress = ProgressBar.create(total: days)
    days.times do |day|
      each_population do |scenario_name, population|
        population.tick(day)
        if @save_details
          population.output << [ day, population.susceptible, population.infected.sum, population.immune, population.died, population.severely_ill.sum, population.resource_controller.beds_available(population),population.did_not_get_bed, population.excess_mortality, population.infected_today, population.recovered_today, population.died_today, population.reaction, population.infection_rate ]
        end
      end
      progress.increment
    end

    if @save_details
      each_population do |scenario_name, population|
        CSV.open(filename_for(scenario_name, population), "wb") do |csv|
          population.output.each do |line|
            csv << line
          end
        end
      end
    end

    # now summarize the difference between the populations
    # export the not sharing scenario
    with_scenario "not sharing" do |s|
      CSV.open(File.join(@data_dir, "summary-#{@states}states-not_sharing.csv"), "wb") do |csv|
        csv << ["State", "Died"]
        s.populations.each do |p|
          csv << [p.name, p.died]
        end
      end 
    end

    with_scenario "sharing" do |s|
      CSV.open(File.join(@data_dir, "summary-#{@states}states-sharing.csv"), "wb") do |csv|
        header = []
        has_written_header = false

        s.populations.each do |sub|
          output = []
          header << "offset"
          output << sub.populations[1].start_at

          sub.populations.each_with_index do |sub_pop,index|
            header << sub_pop.name
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
end


