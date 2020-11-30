# frozen_string_literal: true

require 'minitest/autorun'
require './ass2vtt.rb'

class TestAss2Vtt < Minitest::Test
  def test_youtube_adjust
    text_with_italic = 'this <i>word</i>'
    adjusted_text = Ass2Vtt.youtube_adjust(text_with_italic)

    assert_equal 'this<i> word</i>', adjusted_text
  end
end
