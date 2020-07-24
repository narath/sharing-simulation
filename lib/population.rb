
POPULATION = 4000000

R0 = 4.93
Rt = 1.01

DURATION = 14 # days

SEVERELY_ILL = 0.035 # of those @infected
DEATH_RATE = 0.01 # for those @infected

HOSPITAL_BEDS_PER_CAPITA = 2.77/1000
ICU_BEDS_PER_CAPITA = 29.4/100000

# states react after a period of time
# they react to a doubling of infections
# with this reaction it reduces to the Rt
# most states relax when the new daily infections is less than 100/100,000
RELAX_WHEN_NEW_DAILY_INFECTIONS_IS_LESS_THAN = (100.0/100000 * POPULATION).round

# Alternative relax when the number of new infections is decreasing (this might already always be happening)

class Population
  attr_accessor :r0, :rt, :reaction_time_to_distance, :reaction_time_to_reopen, :relax_when_new_daily_infections_is_less_than
  attr_reader :susceptible, :infected, :severely_ill, :immune, :died
  attr_reader :infection_rate
  attr_reader :reaction
  attr_reader :infected_today, :recovered_today, :died_today, :severely_ill_today
  attr_reader :expected_mortality, :excess_mortality, :icu_beds_available, :did_not_get_bed

  def initialize(r0: R0, rt: Rt, reaction_time_to_distance: 2, reaction_time_to_reopen: 2, relax_when_new_daily_infections_is_less_than: RELAX_WHEN_NEW_DAILY_INFECTIONS_IS_LESS_THAN)
    @r0 = r0
    @rt = rt
    @reaction_time_to_distance = reaction_time_to_distance
    @reaction_time_to_reopen = reaction_time_to_reopen
    @relax_when_new_daily_infections_is_less_than = relax_when_new_daily_infections_is_less_than

    @susceptible = POPULATION
    @infected = Array.new(DURATION) { 0 }
    @severely_ill = Array.new(DURATION) { 0 }
    @immune = 0
    @died = 0
    @is_distancing = false
    @distance_at = nil
    @relax_at = nil
    @infection_rate = @r0 / DURATION
    @reaction = ""
    # just the ICU beds is not sufficient for this
    # @icu_beds = ICU_BEDS_PER_CAPITA * POPULATION 
    # we assume that a third of hospital beds can be used as icu beds
    @icu_beds = (HOSPITAL_BEDS_PER_CAPITA * POPULATION * 0.33).floor
  end

  def tick(day)
        recovered_or_died = @infected.pop + @severely_ill.pop
        @recovered_today = (recovered_or_died * (1-DEATH_RATE)).round
        @died_today = (recovered_or_died - @recovered_today)

        if @distance_at == day
          @distance_at = nil
          @infection_rate = @rt/DURATION
          @reaction = "distancing"
          @is_distancing = true
        elsif @relax_at == day
          @relax_at = nil
          @infection_rate = @r0/DURATION
          @reaction = "relaxed"
        end

        if day == 0
          @infected_today = 10
        else
          @infected_today = (@infection_rate * @infected.sum).round
          @infected_today = [@infected_today, @susceptible
    ].min
          @severely_ill_today = (@infected_today * SEVERELY_ILL).floor
        end

        if !@distance_at && (@infected_today>(2*@infected[7]))
          @distance_at = day + @reaction_time_to_distance
          @relax_at = nil
          @reaction = "preparing to distance at #{@distance_at}"
        elsif !@distance_at && !@relax_at && @is_distancing && (@infected_today<@relax_when_new_daily_infections_is_less_than)
          @relax_at = day + @reaction_time_to_reopen
          @distance_at = nil
          @reaction = "preparing to relax at #{@relax_at}"
        end

        @susceptible = @susceptible - @infected_today
       
        @icu_beds_available = @icu_beds - @severely_ill.sum
        @severely_ill_today = (@infected_today * SEVERELY_ILL).floor
        # if there are no icu beds available, then all those today who are severely ill and do not get an icu bed will die
        if (@severely_ill_today<@icu_beds_available)
          got_bed = @severely_ill_today
          @did_not_get_bed = 0
        else
          got_bed = @icu_beds_available
          @did_not_get_bed = (@severely_ill_today - @icu_beds_available)
        end
       
        @expected_mortality_today = (recovered_or_died * DEATH_RATE).round
        @excess_mortality = [(@died_today + @did_not_get_bed) - @expected_mortality_today,0].max
        @died_today = @died_today + @did_not_get_bed
        @died = @died + @died_today 
        @immune = @immune + @recovered_today

        @infected.prepend(@infected_today)
        @severely_ill.prepend(got_bed)
  end

end
