
HOSPITAL_BEDS_PER_CAPITA = 2.77/1000
ICU_BEDS_PER_CAPITA = 29.4/100000

class ResourceController
  attr_accessor :name

  def initialize(name = self.class.name)
    @name = name
    @beds = {}
  end

  def register(population)
    @beds[population.name] = default_beds_per_population(population)
  end

  def beds_available(population)
    @beds[population.name]
  end

  def take_beds(population, beds)
    @beds[population.name] = @beds[population.name] - beds
    raise "Too many beds taken" if @beds[population.name]<0
    beds
  end

  def return_beds(population, beds)
    @beds[population.name] = @beds[population.name] + beds
    raise "Too many beds returned" if @beds[population.name]>default_beds_per_population(population)
    beds
  end

  def default_beds_per_population(population)
    # just the ICU beds is not sufficient for this
    # @icu_beds = ICU_BEDS_PER_CAPITA * POPULATION 
    # we assume that a third of hospital beds can be used as icu beds
    (HOSPITAL_BEDS_PER_CAPITA * population.size * 0.33).floor
  end    
end
