# Use cases

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One use case of M.f: `seed`, the input a run starts from; `reference`, the reference answer;
`rubric`, a list of weighted checks, each `{"check", "weight"}`. Status: `active` or `retired`.
