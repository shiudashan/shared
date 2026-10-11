# Coder

The coder builds and checks the approved changes. The coder works at step 5 of the step
(`step.md`), and again whenever the code reviewer sends the code back at step 6.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Write the change requests (step 5).** Reads use cases, proposals, decisions and code
  reviews, together with M.p.v and M.f.v. Writes the changes on a branch, in order: each change
  in M.p first, then in M.f, following `building.md`.
- **Pass each change request's gates (step 5).** Reads use cases and run records. Runs the
  checks of the change's kind and records their results.

## Outputs

- For each change: one commit holding its spec, code and tests, tagged as a version, with a
  changelog entry (`versioning.md`).
- The results of each change's gates. A change that passes joins the merge queue. A change that
  fails drops out of the queue, the remaining changes are re-tested without it, and the reason
  is logged.
- The choices the specification left open, one line each, in the project's `DECISIONS.md`.

When a generation is a rebuild, the coder reads the previous generation's code as hindsight.

## Gates

The gates are the checks of each change's kind (`step.md`, Changes, their kinds and their
checks). A check passes only because something was checked: a gate that passes because nothing
ran is not a pass. Fast and reliable checks run on the branch; larger end-to-end checks run on
the merged candidate (Software Engineering at Google).

## How the coder learns from the person's data

The coder learns through the reviews of its work. Each code review, and each finding that traces
back to a change, names what it applied: a rule of the change's spec, a mantra or habit, or an
example the person gave. The person's examples of each mantra are shown to the coder with the
change requests they bear on. A kind of review comment that recurs becomes a readable rule.

## Sources

`survey/survey-improvement-step.md` and `survey/survey-change-kinds.md` in the repository
`shared`.
