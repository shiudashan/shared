# Decisions

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One decision: `decision`, one of `approve`, `postpone`, `reject`, `release` or `keep`; `about`,
the ids of the proposals, or the versions v and v+1; `reason`. Status: `final` or `reverted`.
