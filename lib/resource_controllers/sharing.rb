require_relative File.join("../", "resource_controller")

class ResourceControllerSharing < ResourceController

  def initialize(name = self.class.name)
    @name = name
    @beds = 0
    @max_beds = 0
  end

  def register(population)
    @beds = @beds + default_beds_per_population(population)
    @max_beds = @max_beds + default_beds_per_population(population)
  end

  def beds_available(population)
    @beds
  end

  def take_beds(population, beds)
    @beds = @beds - beds
    raise "Too many beds taken" if @beds<0
    beds
  end

  def return_beds(population, beds)
    @beds = @beds + beds
    raise "Too many beds returned" if @beds>@max_beds
    beds
  end
end

