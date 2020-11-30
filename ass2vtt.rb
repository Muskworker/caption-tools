#!/usr/bin/ruby -w
# frozen_string_literal: true

require './lib/ass.rb'

class Ass2Vtt
  def self.run
    @file = ARGV[-1]
    @dividing_words = ARGV.include?('--words') || ARGV.include?('-w')

    vtt = ASS.read(@file)
    cues = vtt.cues

    cues.collect! do |cue|
      word_count = cue.split_timed.count
      word_time = cue.length / [word_count + 1, 1].max

      cue.text = youtube_adjust(cue.text) if word_count > 1

      if @dividing_words
        cue.text = cue.split_timed.each_with_index.inject('') do |memo, (obj, i)|
          puts "Failed at #{cue}" if obj.nil?
          prefix = "<#{(cue.start + (i + 1) * word_time)}>"
          split = obj.partition(/[ \-\n]*\Z/)

          memo << "#{split[0]}#{prefix}#{split[1]}"
        end
      end

      # Italics
      cue.text.gsub!(/\*(.+?)\*/, '<i>\\1</i>')

      cue
    end

    i = 0
    while i < cues.size
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
      cues[i - 1].end = cues[i].end if @dividing_words && cues[i - 1] && cues[i - 1].end >= cues[i].start && i > 0

      i += 1
    end

    puts vtt.to_s
  end

  # Kludge for italics bug (an italicized word after a timestamp doesn't get temporally placed, but it works if the opening tag appears before the timestamp)
  # TODO: this doesn't work when cues start with italics and are joined with _
  def self.youtube_adjust(str)
    str.gsub(/ (\*|<[ubi]>)/, '\1 ')
  end
end

Ass2Vtt.run if __FILE__ == $PROGRAM_NAME
