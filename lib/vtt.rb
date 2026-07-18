require_relative 'cue'

class VTT
  attr_accessor :head, :cues

  def initialize(head, cues)
    @head = head
    @cues = cues
  end

  def self.read(file)
    # WebVTT files are always UTF-8, regardless of locale
    vtt = File.read(file, encoding: 'bom|utf-8')

    chunks = vtt.split("\n\n")

    head = chunks[0]
    cues = chunks[1..-1].collect { |cue| parse_cue(cue) }

    new(head, cues)
  end

  def to_s
    head + "\n\n" + cues.sort.collect(&:to_s).join
  end

  # Parse a WebVTT cue block. Delegates to Cue.parse.
  def self.parse_cue(cue)
    Cue.parse(cue)
  end
end
