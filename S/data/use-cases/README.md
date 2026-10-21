# Use cases

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

Optional. One use case of M.f, drawn from the logs by the project's own program when the project
has a use for it: `input`, what a run was given; and, only when someone writes them, `reference`,
the reference answer, and `rubric`, a list of weighted checks, each `{"check", "weight"}`. Status:
`active` or `retired`.
