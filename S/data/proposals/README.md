# Proposals

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One change proposal: `findings`, the run reviews it answers; `gain`; `delta`, what the change
adds, modifies or removes in the spec; `kind`; `design`; `tasks`; `check`; `upsides` and
`downsides`, each a list of `{"what", "amount", "unit"}`, kept side by side; `rank`, its place
in the planner's order; `corrections`, the ids of the proposal reviews and decisions it
received; `changed`, what changed since the last round. Status: `proposed`, `withdrawn`,
`approved`, `postponed` or `done`.
