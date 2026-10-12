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
- **Send proposal reviews upward.** Reads proposal reviews at the proposal reviewer's layer.
  Writes each revised entry into `S/outbox/proposal-reviews/`.
- **Receive proposal reviews from below.** Reads each received entry alone. Accepts or drops the
  entry, with a reason.

## Upstream

The proposal reviewer carries proposal reviews upward, as `upstream.md` states for every role.
The proposal reviewer sends a review when the review's point checks a rule that another
project's proposals also face. When the proposal reviewer revises a review, the proposal
reviewer keeps the feedback's point, the corrections and the disposition word for word, and
replaces the proposal's id and each spec section by what the proposal and the section say. When
the proposal reviewer receives a review, the proposal reviewer accepts the review when the
proposal reviewer reaches the same point and disposition from the review alone, and when the
point serves projects beyond the project the review came from.

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
