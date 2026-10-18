---
name: run-s
description: Run S's step on a layer with the developer, one step at a time (S/specs/step.md, developer mode). Use when the developer asks to run S, to start or continue S's step, or answers S's work at a step.
---

# Running S with the developer

The developer is S's developer. Claude Code runs S's step on a layer (a project or a component)
and works with the developer at the end of each of S's steps, the way f works with the Director
round by round. The state of the step lives in `<layer>/S/steps/<id>/`, not in the chat. A hook
puts that state beside every message the developer sends.

## S's steps and where the developer comes in

| Step | Hand-offs | The developer sees |
|---|---|---|
| 1 monitor | use-cases, runs, monitor | the findings |
| 2–3 propose and review | propose, review (looped) | the proposals with the reviewer's corrections |
| 4 decide | user-review, decide | what was approved, postponed or rejected |
| 5 code | code, trial-runs | each change and its tests and trial runs |
| 6 code review | code-review | the review's comments and outcome |
| 7 release | release, merge, runs-after-release | released or kept, and the merge |

`chain.json`'s `consult` lists the steps the developer is consulted on. Removing a step from it is
how the developer switches that step off; the step's work is then shown with the next consulted
step.

## The loop

1. **Run** the step with `S/src/step.sh <layer>` (or `--from <hand-off>` to resume). It stops at the
   end of a consulted step and leaves `S/steps/<id>/gate`.
2. **Show** the step's work in the developer's terms, from the entries the gate lists, never as raw
   JSON. Read each entry and say what it is:
   - findings: what is wrong, the evidence lines, the severity, what it is judged against;
   - proposals: in their order, each with its gain, cost, kind and check, and the reviewer's
     corrections;
   - decisions: what was approved, postponed or rejected, and why;
   - code: per change, its branch, what the diff does, its tests and trial runs;
   - code review: the comments and the outcome;
   - release: released or kept, the reason, the merge.
3. **Wait** for the developer's answer.
4. **Put the answer into the step** with `S/src/gate.sh <layer>`, giving the developer's words
   verbatim:
   - agreement: `approve "<words>"`; any direction in the words goes to the next role;
   - a correction of the step's work: `reject "<words>"`; the step is done again with the words;
   - the developer's own content, such as a finding or a decision: `takeover "<words>"`, then write
     the entries as the developer gave them, with `"by"` the developer, and resume with the printed
     `step.sh` command;
   - the developer's own edits to an entry: `edit`.
   A question from the developer is answered from the step's files; the step waits until the
   developer answers the step.
5. **Go on** to the next step, and back to 2.

## Staying on the step

- Each reply opens by naming the step it serves, for example "Step 1, monitor:".
- S is changed only through `step.sh` and `gate.sh`, and through the entries the developer gives.
- The developer's words about anything other than the current step are noted, not acted on: a
  comment on f becomes an open run review in `<layer>/S/data/run-reviews/`, `by` the developer, with
  the words verbatim; anything else becomes a line in the step's log. One line says where it went.
  The work switches only when the developer says so.
