require './lib/cue.rb'
require './lib/duration.rb'

class VTT
  attr_accessor :head, :cues

  def initialize(head, cues)
    @head = head
    @cues = cues
  end

  def self.read(file)
    vtt = File.read(file)

    chunks = vtt.split("\n\n")

    head = chunks[0]
    cues = chunks[1..-1].collect { |cue| parse_cue(cue) }

    self.new(head, cues)
  end

  def to_s
    puts head << "\n\n" << cues.sort.collect(&:to_s).join
  end
  
  def self.parse_cue(cue)
    timing = cue.lines[0].partition(' --> ')

    start = Duration.parse(timing[0])
    end_time = Duration.parse(timing[2])

    style = timing[2][/(?<= ).*(?=\n)/]
    text = cue.lines[1..-1].join.strip

    Cue.new(start, end_time, text, style)
  end
end