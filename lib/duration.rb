# require 'time'

class Duration < Numeric
  attr_accessor :seconds

  def initialize(length_in_seconds)
    @seconds = length_in_seconds
  end

  def self.parse(time)
    raise ArgumentError, "#{time} is not a valid timestamp" unless time =~ /(\d+):(\d\d):(\d\d.\d\d\d?)/

    values = time.scan(/(\d+):(\d\d):(\d\d.\d\d\d?)/)[0]

    seconds = values[2].to_f + values[1].to_i * 60 + values[0].to_i * 60 * 60

    self.new(seconds)
  end

  def hours
    @seconds.to_i / 3600
  end

  def minute_part
    (@seconds.to_i % 3600) / 60
  end

  def second_part
    @seconds.to_i % 60
  end

  def millisecond_part
    (@seconds % 1 * 1000).to_i
  end

  def to_s
    "#{hours.to_s.rjust(2, '0')}:#{minute_part.to_s.rjust(2, '0')}:#{second_part.to_s.rjust(2, '0')}.#{millisecond_part.to_s.rjust(3, '0')}"
  end

  def to_f
    @seconds
  end

  def coerce(other)
    [Duration.new(other.to_f), self]
  end

  def <=>(other)
    @seconds <=> other.to_f
  end

  def +(other)
    Duration.new(@seconds + other.to_f)
  end

  def -(other)
    Duration.new(@seconds - other.to_f)
  end

  def *(other)
    Duration.new(@seconds * other.to_f)
  end

  def /(other)
    Duration.new(@seconds / other.to_f)
  end
end