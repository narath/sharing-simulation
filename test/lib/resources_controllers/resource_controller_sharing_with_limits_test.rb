require 'minitest/autorun'

require_relative "../../../lib/resource_controllers/sharing_with_limits"
require_relative "../../../lib/population"

describe ResourceControllerSharingWithLimits do

  it "counts available properly with no limits" do
    rc = ResourceControllerSharingWithLimits.new
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)

    b1 = rc.default_beds_per_population(p1)
    b2 = rc.default_beds_per_population(p2)

    # with no limits on sharing - all beds should be available
    assert_equal b1+b2, rc.beds_available(p1)
  end

  it "counts available properly with 100% limits" do
    rc = ResourceControllerSharingWithLimits.new("100%", limit:100)
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)

    b1 = rc.default_beds_per_population(p1)
    b2 = rc.default_beds_per_population(p2)

    # with no limits on sharing - all beds should be available
    assert_equal b1, rc.beds_available(p1)
  end

  it "counts available properly with 50% limits" do
    rc = ResourceControllerSharingWithLimits.new(limit:50)
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)

    b1 = rc.default_beds_per_population(p1)
    b2 = rc.default_beds_per_population(p2)

    # with no limits on sharing - all beds should be available
    assert_equal b1 + (b2 * 0.5), rc.beds_available(p1)
  end

  it "takes beds fairly when all local beds are used" do
    rc = ResourceControllerSharingWithLimits.new(limit:50)
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)
    p3 = Population.new("s3", rc)

    b1 = rc.default_beds_per_population(p1)
    b2 = rc.default_beds_per_population(p2)
    b3 = rc.default_beds_per_population(p3)

    assert_equal b1, rc.take_beds(p1, b1).count
    assert_equal 2, rc.take_beds(p1, 2).count
    assert_equal b2-1, rc.beds_available_locally(p2)
    assert_equal b3-1, rc.beds_available_locally(p3)
  end

  it "takes beds locally when available" do
    rc = ResourceControllerSharingWithLimits.new
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)

    b1 = rc.default_beds_per_population(p1)
    b2 = rc.default_beds_per_population(p2)

    assert_equal ["s1"], rc.take_beds(p1, 1)
  end

  it "takes beds remotely when available" do
    rc = ResourceControllerSharingWithLimits.new
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)

    b1 = rc.default_beds_per_population(p1)
    b2 = rc.default_beds_per_population(p2)

    rc.take_beds(p1,b1)
    assert_equal ["s2"], rc.take_beds(p1, 1)
  end

  it "takes beds fairly remotely when available" do
    rc = ResourceControllerSharingWithLimits.new
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)
    p3 = Population.new("s3", rc)

    b1 = rc.default_beds_per_population(p1)

    rc.take_beds(p1,b1)
    assert_equal ["s2", "s3"], rc.take_beds(p1, 2)
  end

  it "returns beds to the location taken from" do
    rc = ResourceControllerSharingWithLimits.new
    p1 = Population.new("s1", rc)
    p2 = Population.new("s2", rc)
    p3 = Population.new("s3", rc)

    b1 = rc.default_beds_per_population(p1)

    taken1 = rc.take_beds(p1,b1)
    taken2 = rc.take_beds(p1,2)
    assert_equal b1-1, rc.beds_available_locally(p2)
    assert_equal b1-1, rc.beds_available_locally(p3)
    assert_equal 0, rc.beds_available_locally(p1)

    rc.return_beds(p1, taken2)
    assert_equal b1, rc.beds_available_locally(p2)
    assert_equal b1, rc.beds_available_locally(p3)
    assert_equal 0, rc.beds_available_locally(p1)
  end

end
