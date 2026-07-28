# Contributing

Thanks for helping out. Small, focused PRs merge fastest.

## Development

- `make test` — the suite, under [vusted](https://github.com/notomo/vusted) (`luarocks --lua-version=5.1 install vusted`). Run it before every commit.
- `make format` — stylua. CI runs `stylua --check lua test`, so an unformatted file fails the build.
- `COVERAGE=1 make test` — writes `luacov.stats.out`; needs `luacov` and `luacov-reporter-lcov` on `LUA_PATH`. Config is in `.luacov`.
- `make demo` — re-records the README gifs with [vhs](https://github.com/charmbracelet/vhs). The tapes load your own Neovim config rather than a pinned one, so this needs the plugin checked out where that config picks it up, and your gifs will not match the committed ones byte for byte. Only run it when a demo is actually out of date.

Add or extend a test for any behavior change. `test/picker_spec.lua`, `test/input_spec.lua` and `test/output_spec.lua` each have a small helper at the top — copy the nearest existing case.

A new color format is usually three files and their tests: a picker under `lua/c3po/picker/` (reads it), an output under `lua/c3po/output/` (writes it), and an entry in `recognize.pattern` in `lua/c3po/config/default.lua` (ties the two to an input). `doc/c3po.txt` lists the presets and has to grow the same entry.

## Commits and PR titles

PRs are squash-merged and releases are cut by release-please from the commit history, so **PR titles must follow [Conventional Commits](https://www.conventionalcommits.org)** (`feat: …`, `fix: …`, `docs: …`). CI checks the title; `feat` and `fix` drive the version bump and the changelog.

If a change touches the config surface, the commands, or a color format, update `README.md` and `doc/c3po.txt` in the same PR.

## AI-assisted contributions

AI assistance (Copilot, Claude, etc.) is welcome, with three rules:

1. **Disclose it** in the PR description. A one-liner is fine.
2. **You must understand and have tested the change yourself** — run `make test` locally. You are the author; "the model wrote it" is not a review response.
3. **No unreviewed dumps.** Large AI-generated diffs with no accompanying reasoning, and AI-generated bug reports without a reproducible case, will be closed.

## Bug reports

Use the issue form. For anything about a color being read or written wrongly, the fastest report is the literal text in the buffer, the `pickers`/`outputs` you have configured, and what you expected instead — for example "`{Gray}{8}` highlights as black, expected mid grey". Colour bugs are nearly always reproducible from one line of a file.
