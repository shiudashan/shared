# Sync

Sync brings shared's S into a project. A project is a git repository that pins `shared` as a
git submodule at `<project>/shared`. Each project takes shared's files and keeps its own
customisations.

## Steps

0. **Pin.** The project adds `shared` as a submodule:
   `git submodule add <shared's URL> shared`. Git records the pinned commit.
1. **Make the project's sync workflow.** The project copies `shared/S/src/sync.sh` to
   `<project>/S/src/sync.sh` and customises it: its paths, its data folder, and its own additional
   steps. The workflow is a shell file of steps. A step that needs judgement is a `claude -p`
   call; a mechanical step is a plain command.
2. **Run** `<project>/S/src/sync.sh <project>`. It does the following.
   1. **Documents.** `shared/survey/` goes to `<project>/S/survey/`. `shared/S/specs/` goes to
      `<project>/S/specs/`, for the project to customise.
   2. **Config.** `shared/S/config/CLAUDE.md` goes to `<project>/CLAUDE.md`: the general rules are
      joined above the project's own sections, by a `claude -p` step.
      `shared/S/config/.claude/settings.json` is merged with the project's own
      `<project>/.claude/settings.json`, by a `claude -p` step. `shared/S/config/.claude/hooks/` goes
      to `<project>/.claude/hooks/`, and `shared/S/config/.claude/skills/` to
      `<project>/.claude/skills/`.
   3. **Data.** Each `shared/S/data/<type>/` goes to `<project>/S/data/<type>/`. Each
      `shared/S/outbox/<type>/` goes to `<project>/S/outbox/<type>/`, empty but for a `.gitkeep`,
      so the project's sending agents find the outbox (`upstream.md`).
   4. **Programs.** `shared/S/src/upstream.sh` goes to `<project>/S/src/upstream.sh`. Each
      `shared/S/src/agents/<role>/` goes to `<project>/S/src/agents/<role>/`. Then a
      `claude -p` step per role customises the agent for the project as a whole: what the
      project is, how the project lays out its prototypes and their generations, the project's
      release rules, standards, languages and review rules. The customisation names no single
      prototype or generation; the project's own sync adds what is specific to a generation
      when the project syncs a generation.
   5. **Report.** Sync lists what it added, updated, merged and removed, and every conflict.
      The project reviews the changes, customises them, and commits them.

`shared/README.md` is not synced.

## Later runs

A later run starts when the project moves the pin: `git submodule update --remote shared`.

- Step 1 merges any change to `shared/S/src/sync.sh` into the project's copy, and the merged script
  runs.
- Each change in shared since the last sync is merged into the project's copy with a three-way
  merge (`git merge-file`). The three versions are the file at the previously pinned commit, the
  file at the newly pinned commit, and the project's copy.
- The project's customisations and data are never overwritten. A file the project changed and
  shared did not stays as it is. A file shared changed and the project did not takes shared's
  version. Where both changed the same lines, the conflict is left marked in the file, and sync
  exits with status 1.
- A file shared removed is removed from the project if the project had not changed it, and kept
  and reported if it had. A file the project deleted stays deleted.

`<project>/S/.synced-from` holds the commit of shared that the project was last synced to. It
is the base of the three-way merge. The first run is the run with no `.synced-from`.

An existing project follows sync.sh's intention where the script cannot run as it stands.

## Sources

Git submodules; Copier's `copier update`, which reapplies a project's diff from the old template
onto the new one with `git merge-file` (`survey/survey-layered-templates.md` in the repository
`shared`).
