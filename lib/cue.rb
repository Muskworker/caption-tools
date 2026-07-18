require 'strscan'
require_relative 'duration'

# An individual caption.
class Cue
  include Comparable
  attr_accessor :start, :end, :text, :style

  def self.parse(cue)
    timing = cue.lines[0].partition(' --> ')

    start = Duration.parse(timing[0])
    end_time = Duration.parse(timing[2])

    style = timing[2][/(?<= ).*(?=\n)/] || ''
    text = cue.lines[1..-1].join.strip

    new(start, end_time, text, style)
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
    "#{@start} --> #{@end}#{" #{@style}" unless style.empty?}\n" << @text << "\n\n"
  end

  def split_lines
    Cue.split_lines(self)
  end

  # TODO: Fails on multiline bracketed cues (e.g. [a long\nsound effect])
  def self.split_lines(cue)
    first_line_time = cue.text.lines[0][/<(\d+:\d\d:\d\d.\d\d\d)>[ -]?\n$/, 1]
    cue_c_start =
      if first_line_time
        Duration.parse(first_line_time)
      else
        cue.start
      end

    cue_a = Cue.new(cue.start, cue_c_start, cue.text.lines[0].strip, cue.style)
    if cue.text.lines.count > 2
      cue_c = split_lines(Cue.new(cue_c_start, cue.end, cue.text.lines[1..-1].join.strip, cue.style))

      [cue_a, *cue_c]
    else
      cue_c = Cue.new(cue_c_start, cue.end, cue.text.lines[1..-1].join.strip, cue.style)

      [cue_a, cue_c]
    end
  end

  # Split a cue into multiple cues based on the presence of timecodes.
  # Returns: An array of Cue objects.
  def split
    cues = @text.split(/<(\d+:\d\d:\d\d.\d\d\d)>/)
    next_start = @start
    cues.each_slice(2).collect do |(text, time)|
      time = time ? Duration.parse(time) : @end
      Cue.new(next_start, next_start = time, text, style)
    end
  end

  # TODO: style (probably hard)
  # Convert a cue to an XML string.
  def to_xml
    "<p begin=\"#{@start.seconds}s\" end=\"#{@end.seconds}s\">" \
    << split.collect do |cue|
      "\n<span begin=\"#{cue.start.seconds}s\">#{cue.text}</span>"
    end.join \
    << "\n</p>\n"
  end

  # Convert an array of cues to an XML string.
  def self.to_xml(cues)
    "<div region=\"r1\">\n" \
    << cues.collect(&:to_xml).join \
    << "\n</div>\n"
  end

  # Compare cues by start time.
  def <=>(other)
    @start <=> other.start
  end

  # Items that take up time:
  # - Words.
  # - Bracketed expressions, unless linked via "[_" or "_]"
  # Items that don't take up time:
  # - Bracketed expressions linked with "[_" or "_]"
  # - Speaker introductions, such as:
  #   SPEAKER:
  #   >> SPEAKER:
  #   SPEAKER (doing thusly):
  #   >> SPEAKER (doing thusly):
  # - token boundaries: [ \-\n]
  # Returns: An array of strings.
  def split_timed
    scanner = StringScanner.new(text)
    tokens = []
    append = false
    will_append = false
    brackets = 0
    word_divider = /[ \-\n]+|\Z/

    # Check for speaker
    if scanner.peek(2) == '>>' || /[[:lower:]]|\[/ !~ (scanner.check_until(/:/) || 'no')
      append = true
      tokens << scanner.scan_until(/:[ \n]+/)
    end

    until scanner.eos?
      next_word = scanner.scan_until(word_divider)
      brackets += next_word.count('[') - next_word.count(']')
      append ||= next_word.start_with?('[_')
      will_append = next_word =~ (/_\]#{word_divider}/)
      next_word = next_word.sub(/\[_/, '[').sub(/_\]/, ']')

      if append
        (tokens.last || tokens) << next_word
      else
        tokens << next_word
      end

      append = will_append || brackets > 0
    end

    tokens.compact
  end

  # Merge cues that are onscreen at the same time into single stacked cues,
  # for renderers (i.e. YouTube, once any cue in the file carries settings)
  # that superimpose concurrent cues instead of rolling them up.
  # Cues are grouped by their settings string first, so captions anchored
  # to different screen regions are never merged together.
  # Returns: A new array of Cue objects, sorted by start time.
  def self.merge_concurrent(cues)
    cues.group_by { |cue| cue.style.to_s }.values.flat_map do |group|
      cluster_concurrent(group).flat_map do |cluster|
        cluster.count > 1 ? merge_cluster(cluster) : cluster
      end
    end.sort
  end

  # Chain cues into clusters where each cue starts before the cluster ends.
  # Returns: An array of arrays of Cue objects.
  def self.cluster_concurrent(cues)
    cluster_end = nil

    cues.sort.each_with_object([]) do |cue, clusters|
      if cluster_end && cue.start < cluster_end
        clusters.last << cue
        cluster_end = [cluster_end, cue.end].max
      else
        clusters << [cue]
        cluster_end = cue.end
      end
    end
  end

  # Split a cluster's timeline at every cue boundary and emit one cue per
  # segment, stacking the text of every cue active during that segment
  # (earliest first, matching roll-up order).
  # Returns: An array of Cue objects.
  def self.merge_cluster(cluster)
    bounds = cluster.flat_map { |cue| [cue.start, cue.end] }.sort.uniq(&:to_f)

    bounds.each_cons(2).collect do |seg_start, seg_end|
      active = cluster.select { |cue| cue.start <= seg_start && cue.end >= seg_end }
      next if active.empty?

      new(seg_start, seg_end, active.collect(&:text).join("\n"), active.first.style)
    end.compact
  end

  # A visual effect that stretches the appearance of an ellipsis across a pause.
  def self.stretch_ellipses(paused_cue, resumed_cue)
    paused_cue.text = paused_cue.text.sub(/\.\.\.(<[^<]*?>)$/, '\\1')
    interval = resumed_cue.start - paused_cue.end

    words = %w[. . .]
    dot_time = interval / 4

    stretched_text = words.each_with_index.inject('') do |memo, (obj, j)|
      memo + "#{obj}<#{paused_cue.end + (j + 1) * dot_time}>"
    end

    paused_cue.text << stretched_text
    paused_cue.end = resumed_cue.start
  end
end
