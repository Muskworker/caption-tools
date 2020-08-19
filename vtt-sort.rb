#!/usr/bin/ruby -w

require './lib/vtt.rb'

@file = ARGV[0]
vtt = VTT.read(@file)

puts vtt.to_s