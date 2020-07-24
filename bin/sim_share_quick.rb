# Ruby simple simulation of COVID
require 'csv'

POPULATION = 4000000

R0 = 4.93
Rt = 1.01

DURATION = 14 # days

SEVERELY_ILL = 0.035 # of those infected
DEATH_RATE = 0.01 # for those infected

HOSPITAL_BEDS_PER_CAPITA = 2.77/1000
ICU_BEDS_PER_CAPITA = 29.4/100000

# states react after a period of time
# they react to a doubling of infections
# with this reaction it reduces to the Rt

REACTION_TIME = 2 # days

# most states relax when the new daily infections is less than 100/100,000
RELAX_WHEN_NEW_DAILY_INFECTIONS_IS_LESS_THAN = (100.0/100000 * POPULATION).round

susceptible = POPULATION
infected = Array.new(DURATION) { 0 }
severely_ill = Array.new(DURATION) { 0 }
immune = 0
died = 0
has_distanced = false
distance_at = nil
relax_at = nil

# just the ICU beds is not sufficient for this
# icu_beds = ICU_BEDS_PER_CAPITA * POPULATION 
# we assume that a third of hospital beds can be used as icu beds
icu_beds = (HOSPITAL_BEDS_PER_CAPITA * POPULATION * 0.33).floor

beds_available = []

CSV.open("data/sirs.csv", "wb") do |output|

  output << ["day", "susceptible", "infected", "immune", "died", "severely_ill", "icu_beds_available", "died_because_of_no_bed", "excess_mortality", "infected_today", "recovered_today", "died_today", "reaction"] 
  infection_rate = R0 / DURATION
  reaction = ""

  (365*2).times do |day|
    recovered_or_died = infected.pop + severely_ill.pop
    recovered = (recovered_or_died * (1-DEATH_RATE)).round
    died_today = (recovered_or_died - recovered)

    if distance_at == day
      distance_at = nil
      infection_rate = Rt/DURATION
      reaction = "distancing"
      has_distanced = true
    elsif relax_at == day
      relax_at = nil
      infection_rate = R0/DURATION
      reaction = "relaxed"
    end

    if day == 0
      infected_today = 10
    else
      infected_today = (infection_rate * infected.sum).round
      infected_today = [infected_today, susceptible].min
      severely_ill_today = (infected_today * SEVERELY_ILL).floor
    end

    if !distance_at && (infected_today>(2*infected[7]))
      distance_at = day + REACTION_TIME
      relax_at = nil
      reaction = "preparing to distance at #{distance_at}"
    elsif !distance_at && !relax_at && has_distanced && (infected_today<RELAX_WHEN_NEW_DAILY_INFECTIONS_IS_LESS_THAN)
      relax_at = day + REACTION_TIME
      distance_at = nil
      reaction = "preparing to relax at #{relax_at}"
    end

    susceptible = susceptible - infected_today
   
    icu_beds_available = icu_beds - severely_ill.sum
    severely_ill_today = (infected_today * SEVERELY_ILL).floor
    # if there are no icu beds available, then all those today who are severely ill and do not get an icu bed will die
    if (severely_ill_today<icu_beds_available)
      got_bed = severely_ill_today
      did_not_get_bed = 0
    else
      got_bed = icu_beds_available
      did_not_get_bed = (severely_ill_today - icu_beds_available)
    end
   
    expected_mortality = (recovered_or_died * DEATH_RATE).round
    excess_mortality = [(died_today + did_not_get_bed) - expected_mortality,0].max
    died_today = died_today + did_not_get_bed
    died = died + died_today 
    immune = immune + recovered

    infected.prepend(infected_today)
    severely_ill.prepend(got_bed)
    puts severely_ill.sum

    output << [ day, susceptible, infected.sum, immune, died, severely_ill.sum, icu_beds_available - severely_ill_today, did_not_get_bed, excess_mortality, infected_today, recovered, died_today, reaction ]

    beds_available <<  icu_beds_available - severely_ill_today

  end
end

# now we model a variety of scenarios in which we have different offsets, and see what the pooled results would be

MODEL_OFFSET_DAYS = 14

excess_mortality_totals = Array.new(MODEL_OFFSET_DAYS+1) { 0 }

CSV.open("data/offset_model.csv", "wb") do |output|

  output << (1..14).to_a
  days_modelled = beds_available.count
  days_modelled.times do |day|
    result = []
    b = (beds_available[day]<0 ? beds_available[day] : 0) 
    excess_mortality_totals[0] = excess_mortality_totals[0] + b + b # doubled because no sharing
    result << beds_available[day] * 2
    (1..MODEL_OFFSET_DAYS).each do |offset|
      if (day-offset)>0
        b = beds_available[day-offset] + beds_available[day]
        b = (b<0 ? b : 0)
        excess_mortality_totals[offset] = excess_mortality_totals[offset] + b
        result << beds_available[day-offset] + beds_available[day]
      end
    end
    output << result
  end
end

puts excess_mortality_totals.inspect

puts "Done!"

