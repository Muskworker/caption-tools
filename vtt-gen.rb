#!/usr/bin/ruby -w

require './lib/vtt.rb'

@file = ARGV[-1]
@dividing_words = ARGV.include?('--words') || ARGV.include?('-w')

vtt = VTT.read(@file)
# head = vtt.head
cues = vtt.cues

cues.collect! do |cue|
  # word_count = cue.text.lines.join(" ").split(/[ \-\n]+(?![^\[]*\])/).count
  word_count = cue.split_timed.count
  # puts "#{word_count} ≠ old #{old_word_count} for #{cue}\nNEW: #{cue.split_timed}\nOLD: #{cue.text.lines.join(" ").split(/[ \-\n]+(?![^\[]*\])/)}" if word_count != old_word_count
  word_time = cue.length / [word_count, 1].max

  # Kludge for italics bug (an italicized word after a timestamp doesn't get temporally placed, but it works if the opening tag appears before the timestamp)
  # TODO: this doesn't work when cues start with italics and are joined with _
  cue.text.gsub!(/ \*/, '* ') if word_count > 1

  if @dividing_words
    cue.text = cue.split_timed.each_with_index.inject("") do |memo, (obj, i)|
      puts "Failed at #{cue}" if obj.nil?
      prefix = "<#{(cue.start + (i + 1) * word_time)}>"
      split = obj.partition(/[ \-\n]*\Z/)

      memo << "#{split[0]}#{prefix}#{split[1]}"
    end

    # cue.text.gsub!(/[ \-\n]+(?![^\[]*\])/).with_index do |separator, i|
    #     prefix = "<#{(cue.start + (i + 1) * word_time)}>"
    #     #(cue.start + (i + 1) * word_time).strftime("<%H:%M:%S.%L>")
    #
    #     "#{prefix}#{separator}"
    # end
  end

  # Italics
  cue.text.gsub!(/\*(.+?)\*/, '<i>\\1</i>')

  cue
end

i = 0
while i < cues.size
  # Combine cues explicitly joined by an initial '_'
  while cues[i + 1] && cues[i + 1].text.start_with?('_')
    #cues[i].text << cues[i + 1].start.strftime("<%H:%M:%S.%L> ") << cues[i + 1].text[1..-1]
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

  # Add a final cue, for some reason
  #if @dividing_words
  # cues[i].text << "<#{cues[i].end}>" # .strftime("<%H:%M:%S.%L>")
  #end

  if @dividing_words && cues[i].text.lines.count > 1 && cues[i].text.lines[1] != " "
    new_cues = cues[i].split_lines

    nci = 1
    while nci < new_cues.size
      unless new_cues[nci].text.strip.empty?
        if cues[i - 1].end == new_cues[nci - 1].start
          cues[i - 1].end = new_cues[nci - 1].end.dup
        end

        new_cues[nci - 1].end = new_cues[nci].end

        cues[i] = new_cues[nci]
        cues.insert(i, new_cues[nci - 1])

        i += 1
      end
      nci += 1
    end
    # if cues[i - 1].end == new_cues[0].start
    #   cues[i - 1].end = new_cues[0].end.dup
    # end
    #
    # new_cues[0].end = new_cues[1].end
    #
    # cues[i] = new_cues[1]
    # cues.insert(i, new_cues[0])
    #
    # i += 1
  end

  # Keep cue onscreen to scroll onto next
  if @dividing_words && cues[i - 1] && cues[i - 1].end >= cues[i].start && i > 0
    cues[i - 1].end = cues[i].end
    # cues[i].text << "\n " unless cues[i].text[/\n $/]
  end

  i += 1
end

puts vtt.to_s
#puts head << "\n\n" << cues.collect(&:to_s).join
# puts <<-HEADER
# <tt ttp:cellResolution="60 20" xml:lang="en" xmlns="http://www.w3.org/ns/ttml"
#   xmlns:ttp="http://www.w3.org/ns/ttml#parameter" xmlns:tts="http://www.w3.org/ns/ttml#styling">
#   <head>
#     <layout>
#       <region xml:id="r1" tts:color="white" tts:origin="10c 4c" tts:extent="40c 5c" tts:displayAlign="after"/>
#     </layout>
#   </head>
#   <body>
# HEADER
# puts Cue.to_xml(cues)
# puts "</body></tt>"