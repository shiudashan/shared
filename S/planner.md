# Planner

The automatic planner proposes changes to M.p and M.f. It works at step 2 of `method.md`, and
refines its proposals in the loops of steps 3 and 4.

## Job

From the findings of step 1, the planner writes change proposals and orders them. It proposes;
it changes nothing.

It fixes the general issue a finding shows, not the symptom. It asks what in M's design let the
fault happen, and changes that (`method.md`, Bugs indicate poor architecture).

## Inputs

- The findings, each with its symptom, its reference and its severity.
- M.p.v: the specification of the system and of each component.
- The names of the files of M.f that carry the behaviour out.
- On a later round: the reviews of step 3, and the feedback and corrections of step 4.

## Outputs

Proposals, in order. Each proposal states:
- **the finding** it answers;
- **the gain:** what improves, and by how much;
- **the delta to M.p.v:** what the change adds, modifies or removes in the specification;
- **the kind:** one of the kinds in `method.md`;
- **the design:** what then changes in the prompts or the code, each file named;
- **the tasks:** the steps of the work, in order;
- **the check:** the check of its kind, with every number written before the run;
- **upsides and downsides,** quantified.

A limit the proposal adds needs an enforcer in the program. A line in a prompt that only asks
is not one.

Proposals too slight to matter are not written.

## Ordering

The order is the planner's alone. The planner orders by cost of delay divided by duration
(CD3; SAFe's WSJF). Cost of delay counts the value to users, the time criticality, and the risk
the change removes. Estimates are rough and relative, discounted by confidence or given as
ranges. An estimate is refined only where the refinement could change the order (Hubbard's value
of information). The order is redone every step.

## In the loops

- **With the proposal reviewers (step 3).** The planner revises each proposal in place, from the
  reviews, and says what changed. The planner may withdraw a proposal. The loop ends when further
  review can no longer materially change the top proposals.
- **With the decision maker (step 4).** Feedback and corrections from the simulated user and the
  person send the proposals back to the planner. Proposals not approved are postponed, kept in
  the backlog, and may be proposed again.

## How it learns from the person's data

The decision maker's feedback and numerical corrections at step 4 are in-iteration data. They
show how the person weighs gains, costs and risks. For a new round, the planner is shown the
past proposals nearest to the current ones, each with the person's decision, corrections and
reason, approved and turned down alike. A correction the person makes again and again becomes a
readable rule, kept beside the examples once it holds across several of the person's decisions.
Agreement between the planner's order and the person's order is measured as the reviewers'
agreement is (`reviewers.md`).

The prompt is `prompts/planner.txt`.

## Sources

`survey/survey-improvement-step.md`, `survey/survey-development-flow.md` and
`survey/survey-simulated-reviewer.md` in the repository `shared`.
