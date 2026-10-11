# Proposal reviews

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One review of one proposal: `proposal`; `feedback`, in words; `corrections`, each `{"field",
"from", "to", "reason"}`; `disposition`, the recommendation: approve, postpone or reject;
`after`, what changed in the proposal after the review. Status: `open` or `answered`.
