require_relative File.join("../", "resource_controller")

class ResourceControllerSharingWithLimits < ResourceController
  attr_reader :limit

  # beds is a hash by name of the population
  # limit = the percentage of beds that are kept for local use only
  def initialize(name = self.class.name, limit: 0)
    @name = name
    @beds = {}
    @max_beds = {}
    @limit = limit
  end

  def register(population)
    @beds[population.name] = {
      available: default_beds_per_population(population),
      max: default_beds_per_population(population), 
      used_locally: 0 }
  end

  # beds available for a population
  # is the number of beds available locally
  # and the number of beds available non locally
  def beds_available(population)
    beds_available_locally(population) + beds_available_shared(population)
  end

  def beds_available_locally(population)
    @beds[population.name][:available]
  end

  def beds_available_shared(population)
    result = 0
    @beds.each do |key, value|
      next if key == population.name
      result += beds_available_for_sharing(key)
    end
    result
  end

  # take beds locally if available
  # if not available locally, take as many beds as possible
  # then take equally from all those available in the rest
  # it returns an array with the name of each of the populations where this was taken from
  def take_beds(population, beds)
    raise "Too many beds taken" if beds_available(population)<beds
    result = []

    local = beds_available_locally(population)
    if (local>=beds)
      @beds[population.name][:available] -= beds
      @beds[population.name][:used_locally] += beds
      result += (1..beds).collect {|c| population.name } 
    else
      if local>0
        @beds[population.name][:available] -= local
        @beds[population.name][:used_locally] += local
        result += (1..local).collect { |c| population.name }
      end
      
      beds_needed = beds - local
      while beds_needed>0
        @beds.each do |k, v|
          break if beds_needed<=0
          next if k == population.name
          if beds_available_for_sharing(k)>0
            v[:available] -= 1
            beds_needed -= 1
            result += [k]
          end
        end
      end
    end
    result
  end

  # when returning beds, we expect an array that is the name of each location to return a bed to
  def return_beds(population, beds)
    beds.each do |from_location|
      @beds[from_location][:available] += 1
      if from_location==population.name
        @beds[from_location][:used_locally] += 1
      end
      raise "Too many beds returned" if @beds[from_location][:available]>@beds[from_location][:max]
    end
    beds.count
  end

  def beds_available_for_sharing(name)
    limit_beds = @beds[name][:max] * @limit / 100
    [@beds[ name][:available] - limit_beds, 0].max
  end

end


