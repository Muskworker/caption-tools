# frozen_string_literal: true

require 'minitest/autorun'
require './lib/ass.rb'

describe ASS do
  CUE_WITH_BOLD = "Dialogue: 0,0:05:29.78,0:05:31.74,Default,,0,0,0,,Here's a {\\b1}bold{\\b0} word.\n"
  CUE_WITH_ITALICS = "Dialogue: 0,0:05:29.78,0:05:31.74,Default,,0,0,0,,Here's an {\\i1}italic{\\i0} word.\n"
  CUE_WITH_UNDERLINE = "Dialogue: 0,0:05:29.78,0:05:31.74,Default,,0,0,0,,Here's an {\\u1}underlined{\\u0} word.\n"
  CUE_WITH_KARAOKE = "Dialogue: 0,0:12:54.46,0:12:54.76,Default,,0,0,0,,{\\k12}Timed {\\k18}words."

  it 'should recognize italics syntax' do
    ASS.parse_cue(CUE_WITH_ITALICS).text.must_include('<i>italic</i>')
  end

  it 'should recognize bold syntax' do
    ASS.parse_cue(CUE_WITH_BOLD).text.must_include('<b>bold</b>')
  end

  it 'should recognize underline syntax' do
    ASS.parse_cue(CUE_WITH_UNDERLINE).text.must_include('<u>underlined</u>')
  end

  it 'should recognize karaoke syntax' do
    ASS.parse_cue(CUE_WITH_KARAOKE).text.must_include('Timed<00:12:54.580> words.<00:12:54.760>')
  end
end
