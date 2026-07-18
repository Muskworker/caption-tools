#!/usr/bin/ruby -w
# frozen_string_literal: true

require './lib/vtt'

# Merge concurrently-active cues (per settings group) into stacked cues,
# so YouTube keeps the roll-up look in files that contain positioned cues.
@file = ARGV[0]
vtt = VTT.read(@file)
vtt.cues = Cue.merge_concurrent(vtt.cues)

puts vtt
