# shared

What every project shares: a development system, S, and the surveys it rests on.

- `S/` is the development system. S builds, reviews and improves a project, one step at a time.
  - `S/specs/` holds the specs: the mantras and habits engineering work is judged by, how to
    build from a specification, versioning, one step of S (`step.md`), one spec per role, the
    data, and sync.
  - `S/data/` holds one folder per type of data, each with its format.
  - `S/agents/` holds one folder per role, with the role's prompt and settings.
  - `S/CLAUDE.md` and `S/.claude/` hold general working rules and hooks for Claude Code.
  - `S/sync.sh` is the sync workflow.
- `survey/` holds surveys of industrial and research practice.

## How a project syncs from shared

1. Pin shared as a submodule: `git submodule add https://github.com/shiudashan/shared shared`.
2. Copy `shared/S/sync.sh` to `S/sync.sh`, and customise it for the project.
3. Run `S/sync.sh .`. It copies the surveys, specs, config, data formats and agents into the
   project, joins `CLAUDE.md` and `.claude/settings.json` with the project's own, and
   customises each agent for the project. Review, customise and commit the result.

To take later changes, move the pin (`git submodule update --remote shared`) and run
`S/sync.sh .` again. It merges shared's changes into the project's copies with a three-way merge,
and leaves the project's own changes in place. The spec is `S/specs/sync.md`.
