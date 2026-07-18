# Repository Guidelines

## Project Structure & Module Organization
- Primary Ruby sources live in `lib/`, with `ass.rb`, `cue.rb`, `duration.rb`, and `vtt.rb` modelling caption data and timing helpers.
- Command-line entry points `ass2vtt.rb`, `vtt-gen.rb`, `vtt-sort.rb`, and `vtt-merge.rb` sit at the repo root; keep new scripts alongside them when they orchestrate conversions.
- Tests live in `test/`, mirroring the lib layout (`test/lib/...`) plus integration coverage in `test_ass2vtt.rb`; add new suites beside the code they exercise.

## Build, Test & Development Commands
- Use Ruby 3.2.2 as pinned in `.ruby-version` (any version manager). The CLI shebangs deliberately use system `/usr/bin/ruby` so the scripts run directly from caption folders; keep new code compatible with Ruby 2.6.
- Run `rake test` from the project root to execute the Minitest suite via the default `Rakefile`.
- Convert captions locally with `ruby ass2vtt.rb -w -m path/to/captions.ass > captions.vtt` (word timing plus concurrent-cue merging); sort existing WebVTT files using `ruby vtt-sort.rb path/to/source.vtt > sorted.vtt` when debugging cue orderings.

## Coding Style & Naming Conventions
- Follow standard Ruby style: two-space indentation, single quotes for plain strings, and trailing newline at file end.
- Classes and modules stay in CamelCase, while methods, files, and variables use snake_case; match filenames to the primary class inside.
- Prefer immutable and expressive transformations (e.g., `gsub` over `gsub!`) and keep `# frozen_string_literal: true` at the top of new Ruby files.

## Testing Guidelines
- Stick with Minitest; place unit tests under `test/lib` and high-level scenarios in `test/` to mirror existing patterns.
- Name test files `test_*.rb` and define methods like `test_handles_karaoke_tags` so failures read clearly.
- When adding conversion logic, craft fixtures or inline strings that cover edge cases (ellipsis stretching, italics, karaoke timings) and assert both timing and text output.

## Commit & Pull Request Guidelines
- Use concise, present-tense commit subjects with an optional scope (`docs: clarify cue splitting`); keep one logical change per commit.
- Reference issues with `closes #N` where relevant and include shell commands or sample inputs in the commit body when behaviour changes.
- Pull requests should summarize intent, list validation commands run (e.g., `rake test`), and attach before/after caption excerpts or screenshots to illustrate user-facing changes.
