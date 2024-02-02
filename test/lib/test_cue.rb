# frozen_string_literal: true

require 'minitest/autorun'
require './lib/cue'
require './lib/ass'

describe Cue do
  HESITATING_CUE = "Dialogue: 0,0:00:02.68,0:00:04.40,Default,,0,0,0,,I see you shiver with antici...\n"
  RESUMING_CUE = "Dialogue: 0,0:00:09.23,0:00:10.28,Default,,0,0,0,,_pation.\n"

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
