# Coder

The automatic coder builds and checks the selected changes. It works at step 5 of `method.md`,
and again whenever the code reviewer of step 6 sends the code back.

## Job

The coder writes the approved change requests on a branch, in order. Each change is made in
M.p first, then in M.f, following "Building from a specification" in `method.md`. Each change
passes the gates of its kind, or is abandoned.

## Inputs

- The change requests approved at step 4, in order, each with its delta to M.p, design, tasks
  and check.
- M.p.v and M.f.v.
- The previous generation's code, read as hindsight when the generation is a rebuild.
- On a later round: the code review of step 6.

## Outputs

- For each change: one commit holding its spec, code and tests, tagged as a version, with a
  changelog entry (`method.md`, Versioning).
- The results of each change's gates. A change that passes joins the merge queue. A change that
  fails drops out of the queue, the remaining changes are re-tested without it, and the reason
  is logged.
- When the candidate v+1 and the current v are run side by side on the same items: the scores
  of the difference, computed by code on metrics fixed before the run.
- The choices the specification left open, one line each, in the project's `DECISIONS.md`.

## Gates

The gates are the checks of each change's kind (`method.md`, Changes, their kinds and their
checks). A check passes only because something was checked: a gate that passes because nothing
ran is not a pass. Fast and reliable checks run on the branch; larger end-to-end checks run on
the merged candidate (Software Engineering at Google).

## How it learns from the person's data

The coder learns through the reviews of its work. Each code review of step 6, and each finding
of step 1 that traces back to a change, is written down with what it applied: a rule of the
change's spec, a mantra or habit of `method.md`, or a reference entry. The person's examples of
each mantra are shown to the coder with the change requests they bear on. A kind of review
comment that recurs becomes a readable rule in the layer where it recurs, and moves up through
upstream when it proves general.

## Sources

`survey/survey-improvement-step.md` and `survey/survey-change-kinds.md` in the repository
`shared`.
