# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require './ass2vtt'

describe Ass2Vtt do
  CUE_WITH_KARAOKE = ASS.parse_cue('Dialogue: 0,0:12:54.46,0:12:54.76,Default,,0,0,0,,{\\k12}Timed {\\k18}words.')

  it 'should recognize karaoke syntax' do
    # Human math would expect the last to be <00:12:54.760>, but yeah.
    _(Ass2Vtt.parse_cue(CUE_WITH_KARAOKE).text).must_include('Timed <00:12:54.580>words.<00:12:54.759>')
  end
end

class TestAss2Vtt < Minitest::Test
  def test_youtube_adjust
    text_with_italic = 'this <i>word</i>'
    adjusted_text = Ass2Vtt.youtube_adjust(text_with_italic)

    assert_equal 'this<i> word</i>', adjusted_text
  end

  def test_default_region_styles_emit_no_settings
    assert_equal '', Ass2Vtt.settings_for('Default')
    assert_equal '', Ass2Vtt.settings_for('region:game')
  end

  def test_musky_region_style_emits_its_position_settings
    assert_equal 'line:50% position:0% size:75% align:left', Ass2Vtt.settings_for('region:musky')
  end

  def test_unmapped_styles_pass_through_verbatim
    assert_equal 'region:mystery', Ass2Vtt.settings_for('region:mystery')
  end

  FIXTURE_ASS = <<~ASS
    [Script Info]
    Title: fixture

    [V4+ Styles]
    Format: Name
    Style: region:musky

    [Events]
    Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
    Dialogue: 0,0:00:01.00,0:00:02.00,region:musky,,0,0,0,,Hi.
  ASS

  def test_run_emits_a_valid_webvtt_document
    fixture = File.join(Dir.tmpdir, 'ass2vtt_fixture.ass')
    File.write(fixture, FIXTURE_ASS)

    output = `ruby #{File.join(__dir__, '..', 'ass2vtt.rb')} "#{fixture}" 2>/dev/null`

    assert output.start_with?("WEBVTT\n\n"), "expected WEBVTT header, got: #{output.lines.first.inspect}"
    assert_includes output, "00:00:01.000 --> 00:00:04.000 line:50% position:0% size:75% align:left\nHi."
    refute_includes output, '#<'
  end
end
