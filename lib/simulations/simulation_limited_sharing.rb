require 'csv'
require 'ruby-progressbar'

require_relative File.join("..","population")
require_relative File.join("..","resource_controller")
require_relative File.join("..","resource_controllers","sharing")
require_relative File.join("..","resource_controllers","sharing_with_limits")
require_relative File.join("..","scenario")
require_relative File.join("..","simulation_base")

class SimulationLimitedSharing < SimulationBase


  def initialize(data_dir, states: 2, pandemic_offset_days_upto: 10)
    @data_dir = data_dir
    @states = states
    @pandemic_offset_days_upto = pandemic_offset_days_upto
    @scenarios = []

    # a collection of independent states not sharing
    # start_dates do not matter
    @scenarios << Scenario.new("not sharing", ResourceController.new) do |scenario|
      @states.times do |n_state|
        scenario.populations << Population.new("s#{n_state}", scenario.resources)
      end
    end

    # we create a series of combinations in which the start date of the pandemic is different
    @scenarios << Scenario.new("sharing") do |scenario|
      @pandemic_offset_days_upto.times do |n|
        scenario.populations << Scenario.new("sharing-#{n}", ResourceControllerSharing.new) do |scenario|
          @states.times do |n_state|
            scenario.populations << Population.new("s#{n_state}", scenario.resources, start_at: n_state*n)
          end
        end
      end
    end 

    # now with limited sharing
    @scenarios << Scenario.new("limited-sharing10") do |scenario|
      @pandemic_offset_days_upto.times do |n|
        scenario.populations << Scenario.new("limited10-#{n}", ResourceControllerSharingWithLimits.new(limit:10)) do |scenario|
          @states.times do |n_state|
            scenario.populations << Population.new("s#{n_state}", scenario.resources, start_at: n_state*n)
          end
        end
      end
    end 
    @scenarios << Scenario.new("limited-sharing20") do |scenario|
      @pandemic_offset_days_upto.times do |n|
        scenario.populations << Scenario.new("limited20-#{n}", ResourceControllerSharingWithLimits.new(limit:20)) do |scenario|
          @states.times do |n_state|
            scenario.populations << Population.new("s#{n_state}", scenario.resources, start_at: n_state*n)
          end
        end
      end
    end 
    @scenarios << Scenario.new("limited-sharing30") do |scenario|
      @pandemic_offset_days_upto.times do |n|
        scenario.populations << Scenario.new("limited30-#{n}", ResourceControllerSharingWithLimits.new(limit:30)) do |scenario|
          @states.times do |n_state|
            scenario.populations << Population.new("s#{n_state}", scenario.resources, start_at: n_state*n)
          end
        end
      end
    end 
  end

  def run
    days = 365*5
    progress = ProgressBar.create(total: days)
    days.times do |day|
      each_population do |scenario_name, population|
        population.tick(day)
      end
      progress.increment
    end

    # now summarize the difference between the populations
    # export the not sharing scenario
    with_scenario "not sharing" do |s|
      CSV.open(File.join(@data_dir, filename_for("not sharing")), "wb") do |csv|
        csv << ["State", "Died"]
        s.populations.each do |p|
          csv << [p.name, p.died]
        end
      end 
    end

    write_scenario "sharing", filename_for("sharing")
    write_scenario "limited-sharing10", filename_for("limited10")
    write_scenario "limited-sharing20", filename_for("limited20")
    write_scenario "limited-sharing30", filename_for("limited30")
  end

  def write_scenario(scenario_name, filename)
    with_scenario scenario_name do |s|
      CSV.open(File.join(@data_dir, filename), "wb") do |csv|
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

  def filename_for(name)
    "summary-limited-#{@states}-#{name}.csv"
  end
end


