# Planner

The planner proposes changes to M.p and M.f. The planner works at step 2 of the step
(`step.md`), and revises its proposals in the loops of steps 3 and 4. It proposes; it changes
nothing.

The planner fixes the general issue a finding shows, not the symptom. It asks what in M's design
let the fault happen, and changes that (`mantras.md`, Bugs indicate poor architecture).

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Write change proposals from findings (step 2).** Reads run reviews, proposals and decisions,
  together with M.p.v and the names of the files of M.f that carry the behaviour out. Writes
  proposals.
- **Quantify upsides and downsides (step 2).** Reads run grades, run reviews and proposals.
  Writes the quantities into each proposal.
- **Order the proposals (step 2).** Reads proposals and decisions. Writes the order.
- **Revise from reviews (steps 3, 4).** Reads proposal reviews and decisions. Revises each
  proposal in place and records what changed. May withdraw a proposal.
- **Send proposals upward.** Reads proposals at the planner's layer. Writes each revised entry
  into `S/outbox/proposals/`.
- **Receive proposals from below.** Reads each received entry alone. Accepts or drops the entry,
  with a reason.

## Upstream

The planner carries proposals upward, as `upstream.md` states for every role. The planner sends
a proposal when the proposal fixes a general issue that another program can share. When the
planner revises a proposal, the planner keeps the findings' verdicts, the delta, the check's
numbers and the quantities of the upsides and downsides, and replaces each file name by the
file's function. When the planner receives a proposal, the planner accepts the proposal when the
planner can tell from the proposal alone which fault the proposal fixes and how the check
decides the change, and when the fix serves programs beyond the program the proposal came from.

## Proposals

Each proposal states:
- **the findings** it answers;
- **the gain:** what improves, and by how much;
- **the delta to M.p.v:** what the change adds, modifies or removes in the specification;
- **the kind:** one of the kinds in `step.md`;
- **the design:** what then changes in the prompts or the code, each file named;
- **the tasks:** the steps of the work, in order;
- **the check:** the check of its kind, with every number written before the run;
- **upsides and downsides,** quantified.

A limit the proposal adds needs an enforcer in the program. A line in a prompt that only asks
is not one. Proposals too slight to matter are not written.

## Ordering

The order is the planner's alone. The planner quantifies each proposal's upsides and downsides,
keeps the quantities side by side, visible with the order, and orders the proposals by weighing
them together. The planner never folds them into a single ratio. What counts as an upside or a
downside is left to the planner and the project. The order is redone every step.

## How the planner learns from the developer's data

The decisions and corrections of step 4 show how the developer weighs gains, costs and risks. For a
new round, the planner is shown the past proposals nearest to the current ones, each with its
decision, corrections and reason, approved and turned down alike. A correction made again and again
becomes a readable rule, kept beside the examples once it holds across several of the developer's
decisions. Agreement between the planner's order and the developer's order is measured as the
reviewers' agreement is (`run-reviewer.md`).

## Sources

`survey/survey-improvement-step.md`, `survey/survey-development-flow.md` and
`survey/survey-simulated-reviewer.md` in the repository `shared`.
