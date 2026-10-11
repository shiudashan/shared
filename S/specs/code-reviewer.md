# Code reviewer

The code reviewer reviews the diff before release, at step 6 of the step (`step.md`). The code
reviewer either accepts the code or sends the code back to the coder with the review. Either way
the review is written down, and the run reviewer reads it at step 1.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Review a diff (step 6).** Reads proposals and code reviews, together with the diff, the
  delta to M.p and the results of the change's gates. Writes a code review.
- **Accept the code (step 6).** Reads code reviews. Writes the outcome "accept" into the code
  review.
- **Send the code back with the review (step 6).** Reads code reviews. Writes the outcome
  "request changes" into the code review, and the coder takes it up.

## Reviews

A review is accept or request changes, with comments, each tied to lines of the diff. Each
comment names the rule it applies: the change's spec, a mantra or habit (`mantras.md`,
`habits.md`), or an example the person gave. A ready-made code-review agent, configured with
the specs and the person's examples, may play the role (survey-ready-made-reviewers). (Google
code review; GitHub's required review, approve or request changes.)

The code reviewer learns from the person's data on the path given in `run-reviewer.md`.

## Sources

`survey/survey-ready-made-reviewers.md`, `survey/survey-simulated-reviewer.md` and
`survey/survey-improvement-step.md` in the repository `shared`.
