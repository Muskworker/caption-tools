# frozen_string_literal: true

require 'minitest/autorun'
require './ass2vtt.rb'

describe Ass2Vtt do
  CUE_WITH_KARAOKE = ASS.parse_cue('Dialogue: 0,0:12:54.46,0:12:54.76,Default,,0,0,0,,{\\k12}Timed {\\k18}words.')

  it 'should recognize karaoke syntax' do
    # Human math would expect the last to be <00:12:54.760>, but yeah.
    Ass2Vtt.parse_cue(CUE_WITH_KARAOKE).text.must_include('Timed <00:12:54.580>words.<00:12:54.759>')
  end
end

class TestAss2Vtt < Minitest::Test
  def test_youtube_adjust
    text_with_italic = 'this <i>word</i>'
    adjusted_text = Ass2Vtt.youtube_adjust(text_with_italic)

    assert_equal 'this<i> word</i>', adjusted_text
  end
end
