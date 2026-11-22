# Fake weather adapter, injected by default in every spec (ADR 0015): no rain unless a spec says how much fell.
class FakeRain
  attr_accessor :result
  attr_reader :calls

  def initialize(result: 0.0)
    @result = result
    @calls = []
  end

  def millimeters(**arguments)
    calls << arguments
    result
  end
end

RSpec.configure do |config|
  config.before { Weather.rain = FakeRain.new }
  config.after { Weather.rain = nil }
end
