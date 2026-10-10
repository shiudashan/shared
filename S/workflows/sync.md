# Sync

Sync brings the layer above's `S/` into a layer's `S/`. It works from the pan-project layer
down: `shared` into a project, then a project into a generation. Each layer takes the layer
above and keeps its own customisations.

```
bun S/src/sync.ts <layer-dir>
```

## The layers it knows

- **A project** has `shared` as a git submodule at `<project>/shared`. The layer above is
  `<project>/shared/S/`.
- **A generation** is a folder of a project, `<project>/<generation>/`. The layer above is
  `<project>/S/`, as committed in the project's repository.

A layer's `S/BASE` records the commit of the layer above that the layer was last synced to: a
commit of `shared` for a project, a commit of the project for a generation. This is the pin of
git submodule practice, kept per layer.

## What sync does

1. **Moves the layer above to its newest commit.** For a project, sync updates the submodule to
   the newest commit of `shared`'s branch (`git submodule update --remote`). For a generation,
   the newest commit is the project's current commit.
2. **Merges each file.** For every file under the layer above's `S/`, at the base commit or at
   the newest commit, sync compares three versions: the base (the layer above at `BASE`), the
   newest (the layer above now), and this layer's own.
   - Unchanged above since the base: this layer's file stays as it is.
   - Changed above, and not changed in this layer: this layer takes the newest version.
   - Changed in both: a three-way merge with `git merge-file`. Where the two changes touch the
     same lines, the file keeps conflict markers, and sync reports it.
   - New above: added to this layer.
   - Removed above: removed from this layer if this layer had not changed it, kept and reported
     if it had.
   - Changed above but deleted in this layer: left deleted, and reported.
3. **Records the new base** in `S/BASE`.

Files that exist only in this layer are never touched. `BASE` itself is never copied down.

The first sync of a layer has no base. Sync copies the layer above's `S/` and records `BASE`. A
file this layer already had and that differs from the layer above is merged against an empty
base, and so is reported as a conflict.

## After sync

Sync does not commit. It prints what it added, updated, merged and removed, and every conflict.
Whoever ran it resolves the conflicts, reviews the changes, and commits them in the layer's
repository, together with the moved submodule pointer for a project. Sync exits with status 1
when a conflict is left, and 0 otherwise.

## When it runs

When a project or a generation starts, and at once after each upstream.

## Sources

Git submodules; Copier's `copier update`, which reapplies a project's diff from the old
template onto the new one with `git merge-file` (`survey/survey-layered-templates.md` in the
repository `shared`).
