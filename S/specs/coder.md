# Coder

The coder builds and checks the approved changes. The coder works at step 5 of the step
(`step.md`), and again whenever the code reviewer sends the code back at step 6.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Write the change requests (step 5).** Reads use cases, proposals, decisions and code
  reviews, together with M.p.v and M.f.v. Writes the changes on a branch, in order: each change
  in M.p first, then in M.f, following `building.md`.
- **Merge a released change (step 7).** Reads the release decision. When the decision maker
  releases v+1, the coder merges each passed change branch into the branch the step started on,
  keeps each change's tag, and checks that branch out. When the decision maker keeps v, the coder
  checks out the branch the step started on and leaves the change branches unmerged.
- **Pass each change request's gates (step 5).** Reads use cases, run records and the change's
  proposal. Commits the change, then runs each command gate through `S/src/gate-run.sh`, which
  records the run.
- **Send a reusable program upward.** Reads the programs the coder wrote at the coder's layer,
  such as a script or a tool another layer can run. Writes each revised change, with the
  program's files, tests and spec, into `S/outbox/changes/`.
- **Receive a change from below.** Reads each received change alone. Accepts or drops the
  change, with a reason.

## Upstream

The coder carries changes upward, as `upstream.md` states for every role. The coder sends a
change when the program does a job that another layer also needs. When the coder revises a
change, the coder replaces each path and name of the coder's layer by the layer above's, and
keeps the program's tests. When the coder receives a change, the coder accepts the change when
the coder can tell from the files and the tests that the program does the job the change states,
and when the program serves layers beyond the layer the change came from. The coder at the upper
layer then applies each accepted change and runs the change's tests.

## Outputs

- For each change: one commit holding its spec, code and tests, tagged as a version, with a
  changelog entry (`versioning.md`).
- The results of each change's gates. A change that passes joins the merge queue. A change that
  fails drops out of the queue, the remaining changes are re-tested without it, and the reason
  is logged.
- The choices the specification left open, one line each, in the project's `DECISIONS.md`.

When a generation is a rebuild, the coder reads the previous generation's code as hindsight.

## Gates

The gates are the checks of each change's kind, written as gates in the proposal (`step.md`,
Changes, their kinds and their checks). A check passes only because something was checked: a
gate that passes because nothing ran is not a pass. The coder runs each command gate with
`S/src/gate-run.sh <layer root> <change> <gate>`, on the committed change with a clean work tree.
The program decides each command gate from those records, not from the coder's reply; the code
reviewer judges the prompt gates. Fast and reliable checks run on the branch; larger end-to-end checks run on
the merged candidate (Software Engineering at Google).

## How the coder learns from the developer's data

The coder learns through the reviews of its work. Each code review, and each finding that traces
back to a change, names what it applied: a rule of the change's spec, a mantra or habit, or an
example the developer gave. The developer's examples of each mantra are shown to the coder with the
change requests they bear on. A kind of review comment that recurs becomes a readable rule.

## Sources

`survey/survey-improvement-step.md` and `survey/survey-change-kinds.md` in the repository
`shared`.
