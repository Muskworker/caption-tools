#!/usr/bin/ruby -w
# frozen_string_literal: true

require './lib/vtt'

@file = ARGV[0]
vtt = VTT.read(@file)

puts vtt
