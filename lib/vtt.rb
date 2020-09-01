require './lib/cue.rb'

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
    cues = chunks[1..-1].collect { |cue| Cue.parse(cue) }

    self.new(head, cues)
  end

  def to_s
    puts head << "\n\n" << cues.sort.collect(&:to_s).join
  end
end