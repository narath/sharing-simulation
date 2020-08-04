
class SimulationBase
  attr_reader :data_dir, :scenarios

  def initialize(data_dir)
    @data_dir = data_dir
    @scenarios = []
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
