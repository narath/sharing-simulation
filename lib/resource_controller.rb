
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

  # returns an array with the location of the bed that has been taken
  def take_beds(population, beds)
    @beds[population.name] = @beds[population.name] - beds
    raise "Too many beds taken" if @beds[population.name]<0
    (1..beds).collect {|c| population.name}
  end

  # accepts an array with a location for each bed taken
  def return_beds(population, beds)
    @beds[population.name] = @beds[population.name] + beds.count
    raise "Too many beds returned" if @beds[population.name]>default_beds_per_population(population)
    raise "Beds from another location returned" if beds.uniq != [ population.name ]
    beds.count
  end

  def default_beds_per_population(population)
    # just the ICU beds is not sufficient for this
    # @icu_beds = ICU_BEDS_PER_CAPITA * POPULATION 
    # we assume that a third of hospital beds can be used as icu beds
    (HOSPITAL_BEDS_PER_CAPITA * population.size * 0.33).floor
  end    
end
