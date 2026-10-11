# Decision maker

The decision maker approves proposals as change requests at step 4 of the step (`step.md`),
and releases v+1 or keeps v at step 7. The decision maker is usually the project's lead
developer. The other roles advise; the decisions are the decision maker's.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Approve change requests (step 4).** Reads run reviews, proposals, proposal reviews and
  decisions. Approves some proposals as change requests for step 5, in order, and postpones the
  rest. Writes a decision for each proposal, with its reason.
- **Release v+1 or keep v (step 7).** Reads use cases, run records, run grades, decisions and
  code reviews. Writes a release decision, with its reason.

## Approving change requests

The reviewed proposals reach the decision maker with their reviews, the user's feedback and
corrections, and a summary of where the reviewers disagree. Feedback and corrections send
proposals back to the planner: a propose-review-decide loop. The decision maker ends the loop by
approving some proposals. Proposals not approved are postponed, stay in the backlog, and may be
proposed again. Heavy review is kept for changes that are hard to undo (Amazon's Type 1
decisions). (Rust, PEP 1, HashiCorp RFCs.)

## Releasing

The decision maker releases v+1 or keeps v, with the code review in hand, and with the graded
runs of the side-by-side comparison when there are any. The release goes to developers. A
release that proves worse is reverted, and a postmortem follows at once. (Software Engineering
at Google; LLVM; feature toggles; DORA on change approval.)

## How the decision maker is checked

Agreement with the person on held-out decisions, by Cohen's kappa, divided by the person's own
consistency, as for the user (`user.md`).

## Sources

`survey/survey-improvement-step.md` and `survey/survey-development-flow.md` in the repository
`shared`.
