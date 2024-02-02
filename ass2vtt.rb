#!/usr/bin/ruby -w
# frozen_string_literal: true

require_relative 'lib/ass'

# Convert ASS (Advanced SubStation) caption files to YouTube's flavor of WebVTT
class Ass2Vtt
  @dividing_words = false
  
  class << self
    attr_accessor :dividing_words
  end
  
  def self.run
    @file = ARGV[-1]
    @dividing_words = ARGV.include?('--words') || ARGV.include?('-w')

    vtt = ASS.read(@file)
    all_cues = vtt.cues

    all_cues.collect! do |cue|
      parse_cue(cue)
    end

    cue_groups = all_cues.group_by(&:style)
    # all_cues.group_by(&:style).each do |style, cues|
    cue_groups.each do |_style, cues|
      i = 0
      while i < cues.size

        # Stretch ellipses
        if @dividing_words && cues[i].text =~ /\.\.\.<[^<]*?>$/ && cues[i + 1]&.text&.start_with?(/_?(\[.*?\])* *[[:lower:]]/)
          Cue.stretch_ellipses(cues[i], cues[i + 1])
          # cues[i].text = cues[i].text.sub(/\.\.\.(<[^<]*?>)$/, '\\1')
          # interval = cues[i + 1].start - cues[i].end
          #
          # words = %w{. . .}
          # dot_time = interval / 4
          #
          # stretched_text = words.each_with_index.inject('') do |memo, (obj, j)|
          #   memo + "#{obj}<#{(cues[i].end + (j + 1) * dot_time)}>"
          # end
          #
          # cues[i].text << stretched_text
          # cues[i].end = cues[i + 1].start
        end

        # Combine cues explicitly joined by an initial '_'
        while cues[i + 1]&.text&.start_with?('_')
          if cues[i + 1].text.start_with?('_<i>') # youtube can't <i> at the beginning of a cue
            partition = cues[i].text.rpartition(/<.*>[ \-\n]*\Z/)
            partition[1].prepend('<i>')
            cues[i].text = partition.join
            cues[i].text << "<#{cues[i + 1].start}> " << cues[i + 1].text.delete_prefix('_<i>')
          else
            cues[i].text << "<#{cues[i + 1].start}> " << cues[i + 1].text[1..-1]
          end
          cues[i].end = cues[i + 1].end
          cues.delete_at(i + 1)
        end

        # Conjoin cues separated by less than 4 seconds,
        # or else pad by 2 seconds
        if cues[i + 1] && (cues[i].end + 4) > cues[i + 1].start
          cues[i].end = cues[i + 1].start
          cues[i].end -= 0.01 unless @dividing_words
        else
          cues[i].end += 2
        end

        if @dividing_words && cues[i].text.lines.count > 1 && cues[i].text.lines[1] != ' '
          new_cues = cues[i].split_lines

          nci = 1
          while nci < new_cues.size
            unless new_cues[nci].text.strip.empty?
              cues[i - 1].end = new_cues[nci - 1].end.dup if cues[i - 1].end == new_cues[nci - 1].start

              new_cues[nci - 1].end = new_cues[nci].end

              cues[i] = new_cues[nci]
              cues.insert(i, new_cues[nci - 1])

              i += 1
            end
            nci += 1
          end
        end

        # Keep cue onscreen to scroll onto next
        if @dividing_words && cues[i - 1] && cues[i - 1].end >= cues[i].start && i.positive?
          cues[i - 1].end = cues[i].end
        end

        i += 1
      end
    end

    vtt.cues = cue_groups.values.flatten

    puts vtt
  end

  # Kludge for italics bug (an italicized word after a timestamp doesn't get temporally placed,
  # but it works if the opening tag appears before the timestamp)
  def self.youtube_adjust(str)
    str.gsub(/ (\*|<[ubi]>)/, '\1 ')
  end

  # The karaoke function code is {\k<duration>}, where <duration> is hundredths of seconds
  def self.karaoke_split(cue)
    cue.text.split(/(?!\\(\\\\)*)(\{\\k(\d*?)\}.*?)/)
  end

  # Divide a cue by karaoke timings
  def self.time_karaoke(cue)
    karaoke_cues = karaoke_split(cue)
    cue.text = karaoke_cues.shift
    latest_start = cue.start

    karaoke_cues.each_slice(3).inject(cue.text) do |memo, (_, time, text)|
      latest_start += time.to_f / 100
      postfix = "<#{latest_start}>"

      memo + text + postfix
    end
  end

  # Divide a cue equally by number of words, sort of
  def self.time_words(cue)
    # Duration of cue / "word" count + 1
    words = cue.split_timed
    word_time = cue.length / (words.count + 1)

    words.each_with_index.inject('') do |memo, (obj, i)|
      word, spacer, = obj&.partition(/[ \-\n]*\Z/)

      memo + "#{word}<#{cue.start + (i + 1) * word_time}>#{spacer}"
    end
  end

  # Cue formatting and timing
  def self.parse_cue(cue)
    karaoke_cue_count = karaoke_split(cue).count
    ass_timed = karaoke_cue_count > 1

    cue.text = youtube_adjust(cue.text) if ass_timed || cue.split_timed.count > 1

    cue.text = if    ass_timed       then time_karaoke(cue)
               elsif @dividing_words then time_words(cue)
               else
                 cue.text
               end

    # Markdown-style talics
    cue.text = cue.text.gsub(/\*(.+?)\*/, '<i>\\1</i>')

    cue
  end
end

Ass2Vtt.run if __FILE__ == $PROGRAM_NAME
