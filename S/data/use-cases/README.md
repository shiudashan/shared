# Use cases

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One use case of M.f: `seed`, the input a run starts from, as a path in the layer; `seedtext`,
the seed's text, word for word; and, only when someone writes them, `reference`, the reference
answer, and `rubric`, a list of weighted checks, each `{"check", "weight"}`. `S/src/record.sh`
records each seed a user gave. Status: `active` or `retired`.
