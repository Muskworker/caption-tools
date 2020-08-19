require 'strscan'
require './lib/duration.rb'

class Cue
  include Comparable
  attr_accessor :start, :end, :text, :style
  
  def self.parse(cue)
    timing = cue.lines[0].partition(' --> ')

    start = Duration.parse(timing[0]) # Time.parse(timing[0])
    end_time = Duration.parse(timing[2]) #Time.parse(timing[2])
    
    style = timing[2].partition(' ')[2].chomp
    text = cue.lines[1..-1].join.strip
    
    self.new(start, end_time, text, style)
  end
  
  def initialize(start, end_time, text, style = '')
    @start = start
    @end = end_time
    @text = text
    @style = style
  end
  
  def length
    @end - @start
  end
  
  def to_s
    #"#{@start.strftime("%H:%M:%S.%L")} --> #{@end.strftime("%H:%M:%S.%L")}\n" << @text << "\n\n"
    "#{@start.to_s} --> #{@end.to_s}#{" #{@style}" unless style.empty?}\n" << @text << "\n\n"
  end
  
  def split_lines
    Cue.split_lines(self)
  end
  
  # TODO: Fails on multiline bracketed cues (e.g. [a long\nsound effect])
  def self.split_lines(cue)
    #cue_c_start = Duration.parse(cue.text.lines[0][/<(\d+:\d\d:\d\d.\d\d\d)>[ -]?\n$/, 1])
    first_line_time = cue.text.lines[0][/<(\d+:\d\d:\d\d.\d\d\d)>[ -]?\n$/, 1]
    cue_c_start = 
      if first_line_time
        Duration.parse(first_line_time)
      else
        cue.start
      end
      
     #Time.parse(cue.text.lines[0][/<(\d+:\d\d:\d\d.\d\d\d)> ?\n$/, 1])
    
    cue_a = Cue.new(cue.start, cue_c_start, cue.text.lines[0].strip, cue.style)
    #cue_c = Cue.new(cue_c_start, cue.end, scrubbed_text.dup << cue.text.lines[1..-1].join.chomp)
    #  cue_c = Cue.new(cue_c_start, cue.end, cue.text.lines[1..-1].join.strip, cue.style)# << cue.end.strftime("<%H:%M:%S.%L>\n "))
    if cue.text.lines.count > 2
      cue_c = split_lines(Cue.new(cue_c_start, cue.end, cue.text.lines[1..-1].join.strip, cue.style))
      
      [cue_a, *cue_c]
    else
      cue_c = Cue.new(cue_c_start, cue.end, cue.text.lines[1..-1].join.strip, cue.style)# << cue.end.strftime("<%H:%M:%S.%L>\n "))
      
      [cue_a, cue_c]
    end
  end
  
  def split
    cues = @text.split(/<(\d+:\d\d:\d\d.\d\d\d)>/)
    next_start = @start
    cues.each_slice(2).collect do |(text, time)|
      time = time ? Duration.parse(time) : @end
      # time = Duration.parse(time) if time
      Cue.new(next_start, next_start = time, text, style)
    end
  end
  
  # TODO: style (probably hard)
  def to_xml
    "<p begin=\"#{@start.seconds}s\" end=\"#{@end.seconds}s\">" \
    << split.collect do |cue|
      "\n<span begin=\"#{cue.start.seconds}s\">#{cue.text}</span>"
    end.join \
    << "\n</p>\n"
  end
  
  def self.to_xml(cues)
    "<div region=\"r1\">\n" \
    << cues.collect(&:to_xml).join \
    << "\n</div>\n"    
  end
  
  def <=>(other)
    @start <=> other.start
  end
  
  # Items that take up time.
  # Words.
  # Bracketed expressions, unless linked via "[_" or "_]"
  # Items that don't take up time.
  # Bracketed expressions linked with "[_" or "_]"
  # Speaker introductions, such as:
  #   SPEAKER:
  #   >> SPEAKER:
  #   SPEAKER (doing thusly):
  #   >> SPEAKER (doing thusly):
  # token boundaries: [ \-\n]
  def split_timed
    # text.lines.join(" ").split(/[ \-\n]+(?![^\[]*\])/)
    scanner = StringScanner.new(text)
    tokens = []
    append = false
    will_append = false
    brackets = 0
    word_divider = /[ \-\n]+|\Z/ # 
    
    # Check for speaker  
    if scanner.peek(2) == ">>" || /[[:lower:]]|\[/ !~ (scanner.check_until(/:/) || "no")
      append = true
      tokens << scanner.scan_until(/:[ \n]+/)
    end
    
    while !scanner.eos?
      next_word = scanner.scan_until(word_divider)
      brackets += next_word.count("[") - next_word.count("]")
      append ||= next_word.start_with?("[_")
      will_append = next_word =~ (/_\]#{word_divider}/)
      next_word = next_word.sub(/\[_/, "[").sub(/_\]/, "]")
      
      if append
        (tokens.last || tokens) << next_word
      else
        tokens << next_word
      end
      
      append = will_append || brackets > 0
    end
    
    tokens
  end
end

