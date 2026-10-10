# Upstream

Upstream carries the named edits from a layer's `S/` up to the layer above's `S/`. It works
from the generation up: a generation into its project, then a project into `shared`. It carries
the edits that serve the layer above, and only those that are named.

```
bun S/src/upstream.ts <layer-dir> <file>...
```

Each file is named relative to the layer's `S/`, with or without the leading `S/`.

## What upstream carries

For each named file, upstream takes the change this layer made since `S/BASE`: the difference
between the layer above's version at `BASE` and this layer's version now. It applies that change
onto the layer above's current version with a three-way merge (`git merge-file`). Changes the
layer above made since `BASE` are kept. A file this layer deleted is deleted above, when the
layer above has not changed it since `BASE`.

A named file this layer has not changed since `BASE` carries nothing, and upstream says so.

## Generation to project

Upstream applies the changes to `<project>/S/` and commits the named files, and only those, in
the project's repository. It refuses to start when the named files of the project's `S/` have
uncommitted changes. When a merge conflicts, upstream commits nothing, leaves the conflict
markers in the project's `S/`, and reports them.

## Project to `shared`

Upstream writes the changes into a separate checkout of the `shared` submodule, on a new branch
from `shared`'s newest main branch, commits them, pushes the branch, and opens a pull request
with `gh pr create`. It does not merge. The pull request is the review: `shared`'s maintainers
merge it or turn it down (inner source). The project's own checkout of `shared` does not move.

When a merge conflicts, upstream pushes nothing and reports where the conflicted checkout was
left.

## Upstream never writes downward

Upstream writes only into the layer above. The layer it carries from, including its `S/BASE`, is
left exactly as it was. The next sync brings the carried change back down; since this layer
already holds it, the merge is clean.

## When it runs

Periodically, whenever an edit in a layer proves useful beyond it, off the critical path, and at
once followed by sync. Curation, the upstream of the person's labels, uses the same workflow.

## Sources

Git submodules; inner source's pull request to the shared repository, reviewed by its
maintainers (`survey/survey-layered-templates.md` in the repository `shared`).
