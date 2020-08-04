# A scenario is a collection of resource allocators and populations with a specific name
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
