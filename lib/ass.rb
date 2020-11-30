# frozen_string_literal: true

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

    new(head, cues)
  end

  def to_s
    puts head << "\n\n" << cues.sort.collect(&:to_s).join
  end

  def self.parse_cue(cue)
    cue = cue.gsub('"', '&quot;')
    cue = CSV.parse_line(cue, liberal_parsing: true)

    start = Duration.parse(cue[1])
    end_time = Duration.parse(cue[2])

    style = cue[3]
    text = cue[9..-1].join(',')
                     .gsub('\N', "\n")
                     .gsub(/(?!\\(\\\\)*)\{\\.*?\}/) { |m| style_code_to_html(m) }
                     .strip

    Cue.new(start, end_time, text, style)
  end

  def self.style_code_to_html(code)
    outcomes = { '{\i1}' => '<i>', '{\i0}' => '</i>',
                 '{\b1}' => '<b>', '{\b0}' => '</b>',
                 '{\u1}' => '<u>', '{\u0}' => '</u>' }

    code.gsub(/.*/, outcomes)
  end
end
