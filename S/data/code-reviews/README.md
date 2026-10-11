# Code reviews

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One review of one diff: `diff`, the commits reviewed; `change`, the id of the proposal it
implements; `comments`, each `{"lines", "text", "rule"}`; `outcome`, `accept` or `request
changes`. Status: `open` or `closed`.
