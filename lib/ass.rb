require './lib/cue.rb'
require 'csv'

class ASS
  attr_accessor :head, :cues

  def initialize(head, cues)
    @head = head
    @cues = cues
  end

  def self.read(file)
    ass = File.read(file)

    chunks = ass.split("\n\n")

    head = chunks[0..2]
    cues = chunks[-1].lines[2..-1].collect { |cue| parse_cue(cue) }

    self.new(head, cues)
  end

  def to_s
    puts head << "\n\n" << cues.sort.collect(&:to_s).join
  end
  
  def self.parse_cue(cue)
    cue = cue.gsub('"', "&quot;")
    cue = CSV.parse_line(cue, liberal_parsing: true)

    start = Duration.parse(cue[1])
    end_time = Duration.parse(cue[2])

    style = cue[3]
    text = cue[9..-1].join(',').gsub(/<\/?i>/, '*').gsub('\N', "\n").strip

    Cue.new(start, end_time, text, style)
  end
end