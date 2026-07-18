# Caption Tools

Caption Tools is a small collection of Ruby utilities for converting and refining caption files. It focuses on turning Advanced SubStation (ASS) transcripts into YouTube-friendly WebVTT, smoothing timing gaps, and keeping cue formatting intact.

## Requirements
- Ruby 3.2.2 (see `.ruby-version`). Use `rbenv install 3.2.2` or your preferred version manager to match the runtime.
- No external gems are required; the scripts rely on Ruby's standard library.

## Getting Started
Clone the repository and ensure the scripts are executable:

```bash
git clone https://github.com/Muskworker/caption-tools.git
cd caption-tools
chmod +x ass2vtt.rb vtt-gen.rb vtt-sort.rb vtt-merge.rb
```

## Usage
- Convert ASS to WebVTT, preserving karaoke timing and optional per-word splits. ASS style names are mapped to VTT position settings via `Ass2Vtt::STYLE_SETTINGS` (`Default`/`region:game` → default position, `region:musky` → mid-screen left; anything else passes through verbatim):
  ```bash
  ruby ass2vtt.rb path/to/source.ass > captions.vtt
  ruby ass2vtt.rb --words path/to/source.ass > captions_word_split.vtt
  ruby ass2vtt.rb --words --merge path/to/source.ass > captions_youtube_ready.vtt
  ```
  `--merge` (`-m`) applies the concurrent-cue stacking of `vtt-merge.rb` inline, for files that use positioned regions.
- Regenerate timestamps inside an existing WebVTT file using cue timing heuristics:
  ```bash
  ruby vtt-gen.rb source.vtt > retimed.vtt
  ```
- Sort a WebVTT file by cue start time (useful after manual edits):
  ```bash
  ruby vtt-sort.rb captions.vtt > captions_sorted.vtt
  ```
- Merge concurrently-active cues so YouTube keeps the roll-up look in files that contain positioned cues (cues are grouped by their settings string, so differently-positioned captions are never merged together). Standalone equivalent of `ass2vtt.rb --merge`, for VTT files edited after conversion:
  ```bash
  ruby vtt-merge.rb captions.vtt > captions_merged.vtt
  ```

Each command reads from the provided path and prints the transformed VTT to STDOUT so you can redirect the result.

## Project Layout
- `ass2vtt.rb`, `vtt-gen.rb`, `vtt-sort.rb`, `vtt-merge.rb`: CLI entry points for conversion, regeneration, sorting, and cue merging.
- `lib/`: Core models for cues (`cue.rb`), durations (`duration.rb`), ASS parsing (`ass.rb`), and WebVTT parsing (`vtt.rb`).
- `test/`: Minitest suites covering conversion helpers and edge cases; run with `rake test`.

## Development
- Run the full test suite locally: `rake test` (there is no Gemfile; only the standard library and Rake are used).
- The scripts prefer immutable string operations and keep `# frozen_string_literal: true` headers. Follow the conventions captured in `AGENTS.md` when contributing.

## Contributing
Please review `AGENTS.md` for coding standards, testing expectations, and pull request guidelines before opening changes. Bug reports and feature ideas are welcome—include example caption snippets and the command you ran when filing issues.
