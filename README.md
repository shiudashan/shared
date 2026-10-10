# shared

The pan-project layer of S, a development system in which a person says what the person wants
and then labels, while S builds, reviews and improves the project.

- **`S/`** holds S's parts that every project uses: the method (`method.md`), the specs of the
  simulated user, the reviewers, the planner and the coder, the working rules for Claude Code
  (`CLAUDE.md`), the prompts, reference feedback, and the two workflows that move content
  between layers, sync and upstream (`workflows/`, implemented in `src/`).
- **`survey/`** holds the surveys of established practice that the method cites.

A project includes this repository as a git submodule at `<project>/shared`, and keeps its own
customised copy of `S/` at `<project>/S/`. A generation of the project keeps another at
`<project>/<generation>/S/`. Sync brings each layer's `S/` down into the next; upstream carries
edits back up.

The workflows need git and Bun. Their tests run with `bun test` in `S/`.
