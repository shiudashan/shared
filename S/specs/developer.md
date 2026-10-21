# Developer

The developer develops M through S, up to the release. The developer reviews the proposals at
step 4 and makes the trial runs of the candidate v+1 at step 5 (`step.md`). The developer judges
as the person who develops the project would. That person plays the developer on top of an AI in
developer mode (`step.md`, "Developer mode"). When the developer has no ground for a judgement,
the developer hands it to that person.

The user is the other side: the user takes a released version and uses it (`user.md`). Trial
runs of an unreleased candidate are the developer's, not the user's.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Review proposals (step 4).** Reads run reviews, proposals, proposal reviews and decisions.
  Writes proposal reviews.
- **Give feedback and corrections (step 4).** Reads proposals, proposal reviews and decisions.
  Writes proposal reviews: textual feedback and numerical corrections, each with its reason.
- **Run M.f side by side, v and v+1 (step 5).** Reads use cases. Runs the current v and the
  candidate v+1 on the same use cases, with `S_RUN_KIND=trial`. Writes run records.
- **Grade a trial run (step 5).** Reads use cases, run records and run grades. Writes a run grade
  with its reason, by the method in `user.md`, "Grading".

## How the developer is checked

- Agreement with the person who develops the project on held-out proposal reviews and
  corrections, by Cohen's kappa, divided by that person's own consistency, as `user.md` does for
  grades.
- Whether the developer ranks v and v+1 the way that person does.

## Sources

`survey/survey-simulated-reviewer.md` and `survey/survey-improvement-step.md` in the repository
`shared`.
