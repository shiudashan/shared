# Run grades

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One grade of one run: `run`; `grade`, a number on a better-to-worse scale from 0 (worst) to 1
(best); `reason`; `grader`, recorded in `by`. Status: `given`, `approved` or `rejected`.
