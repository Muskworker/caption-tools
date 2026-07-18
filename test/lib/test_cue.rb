# frozen_string_literal: true

require 'minitest/autorun'
require './lib/cue'
require './lib/ass'

describe Cue do
  HESITATING_CUE = "Dialogue: 0,0:00:02.68,0:00:04.40,Default,,0,0,0,,I see you shiver with antici...\n"
  RESUMING_CUE = "Dialogue: 0,0:00:09.23,0:00:10.28,Default,,0,0,0,,_pation.\n"
  PLAIN_VTT_CUE = "00:00:01.000 --> 00:00:02.000\nhello"
  STYLED_VTT_CUE = "00:00:01.000 --> 00:00:02.000 line:50% align:left\nhello"

  it 'should round-trip a cue that has no settings' do
    _(Cue.parse(PLAIN_VTT_CUE).to_s).must_equal("00:00:01.000 --> 00:00:02.000\nhello\n\n")
  end

  it 'should round-trip a cue that has settings' do
    _(Cue.parse(STYLED_VTT_CUE).to_s).must_equal("00:00:01.000 --> 00:00:02.000 line:50% align:left\nhello\n\n")
  end

  # If we are splitting words
  # and a unit ends with an ellipsis
  # and the next one begins with a lowercase letter (not counting [sound effects] etc.)
  # then the ellipsis should... be divided out to fill the intervening space.
  it 'should stretch ellipses' do
    Ass2Vtt.dividing_words = true

    hesitate = ASS.parse_cue(HESITATING_CUE)
    resume = ASS.parse_cue(RESUMING_CUE)

    Ass2Vtt.parse_cue(hesitate)
    Ass2Vtt.parse_cue(resume)

    Cue.stretch_ellipses(hesitate, resume)

    _(hesitate.text).must_include('antici<00:00:04.154>.<00:00:05.607>.<00:00:06.815>.')
  end
end

class TestCueMergeConcurrent < Minitest::Test
  POSITIONED = 'line:50% position:0% size:75% align:left'

  def cue(start, end_time, text, style = '')
    Cue.new(Duration.new(start), Duration.new(end_time), text, style)
  end

  def spans(cues)
    cues.collect { |c| [c.start.to_f, c.end.to_f] }
  end

  def test_merges_concurrent_cues_into_stacked_segments
    merged = Cue.merge_concurrent([cue(0, 4, 'one'), cue(2, 4, 'two')])

    assert_equal ['one', "one\ntwo"], merged.collect(&:text)
    assert_equal [[0, 2], [2, 4]], spans(merged)
  end

  def test_chained_overlaps_keep_a_rolling_window
    chain = [cue(0, 4, 'one'), cue(2, 6, 'two'), cue(4, 8, 'three')]
    merged = Cue.merge_concurrent(chain)

    assert_equal ['one', "one\ntwo", "two\nthree", 'three'], merged.collect(&:text)
    assert_equal [[0, 2], [2, 4], [4, 6], [6, 8]], spans(merged)
  end

  def test_leaves_nonconcurrent_cues_untouched
    merged = Cue.merge_concurrent([cue(0, 2, 'one'), cue(3, 5, 'two')])

    assert_equal ['one', 'two'], merged.collect(&:text)
    assert_equal [[0, 2], [3, 5]], spans(merged)
  end

  def test_does_not_merge_cues_with_different_settings
    lyric = cue(0, 4, 'lyric')
    speech = cue(2, 6, 'speech', POSITIONED)
    merged = Cue.merge_concurrent([lyric, speech])

    assert_equal ['lyric', 'speech'], merged.collect(&:text)
    assert_equal ['', POSITIONED], merged.collect(&:style)
  end

  def test_merged_cues_keep_their_settings
    pair = [cue(0, 4, 'one', POSITIONED), cue(2, 4, 'two', POSITIONED)]
    merged = Cue.merge_concurrent(pair)

    assert_equal [POSITIONED, POSITIONED], merged.collect(&:style)
  end

  def test_identical_spans_collapse_into_one_cue
    merged = Cue.merge_concurrent([cue(0, 4, 'one'), cue(0, 4, 'two')])

    assert_equal ["one\ntwo"], merged.collect(&:text)
  end
end
