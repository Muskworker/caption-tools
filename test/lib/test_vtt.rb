# frozen_string_literal: true

require 'minitest/autorun'
require './lib/vtt'

describe VTT do
  PLAIN_CUE = "00:00:01.000 --> 00:00:02.000\nhello"
  STYLED_CUE = "00:00:01.000 --> 00:00:02.000 line:50% align:left\nhello"

  it 'should round-trip a cue that has no settings' do
    _(VTT.parse_cue(PLAIN_CUE).to_s).must_equal("00:00:01.000 --> 00:00:02.000\nhello\n\n")
  end

  it 'should round-trip a cue that has settings' do
    _(VTT.parse_cue(STYLED_CUE).to_s).must_equal("00:00:01.000 --> 00:00:02.000 line:50% align:left\nhello\n\n")
  end

  it 'should render itself as a string rather than printing' do
    vtt = VTT.new('WEBVTT', [VTT.parse_cue(PLAIN_CUE)])

    _(vtt.to_s).must_equal("WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nhello\n\n")
  end
end
