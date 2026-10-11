# Proposal reviewer

The proposal reviewer reviews the proposals at the top of the planner's order, at step 3 of the
step (`step.md`). The reviews go back to the planner. The loop ends when further review can no
longer materially change the top proposals.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Review the top proposals (step 3).** Reads run reviews, proposals, proposal reviews and
  decisions. Writes a proposal review for each.
- **Give textual feedback (step 3).** Reads proposal reviews. Writes the feedback into the
  proposal review.
- **Give numerical corrections (step 3).** Reads proposals and decisions. Writes corrections to
  the proposal's numbers into the proposal review.

## Reviews

For each proposal, the review gives feedback in words, corrections to its numbers (its
quantified upsides and downsides, and its confidence), and a recommended disposition: approve,
postpone or reject. The proposal reviewer recommends; it does not filter. Every proposal the
planner has not withdrawn reaches the decision maker, with its reviews and a summary of where
the reviewers disagree.

**Grounding.** Each point names what it checks against: a section of M.p, a rule of the specs
in `S/specs/`, a finding, or a decision. The checks are consistency with M.p and with the specs,
and a check in the proposal that can decide it (Spec Kit's analyze; Google design review). Heavy
review is kept for changes that are hard to undo (Amazon's Type 1 decisions).

The proposal reviewer learns from the person's data on the path given in `run-reviewer.md`.

## Sources

`survey/survey-simulated-reviewer.md` and `survey/survey-improvement-step.md` in the repository
`shared`.
