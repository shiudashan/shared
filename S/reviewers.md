# Reviewers

The automatic reviewers review on the person's behalf. Each artifact has its own reviewer. The
run reviewer judges runs, the proposal reviewer reviews proposals, and the code reviewer reviews
diffs. No reviewer reviews an artifact it wrote, and the reviewers are advisory: the decision
stays with the decision maker (`method.md`, steps 4 and 7).

## Run reviewer (step 1, monitor)

**Job.** Reads the run records, if there are any, and the code reviews of step 6 in any case,
and writes findings: the areas to improve.

**Inputs.** For each run: the run's facts as the program computes them, the log lines they rest
on, each labelled with its kind of fact, and the reference entries most similar to the run. The
code reviews of the last step.

**Outputs.** Findings. Each finding names:
- the symptom it rests on, in a run record or a code review;
- the reference it is judged against, where one exists: a reference entry of the person's data,
  a test, or a gate;
- its severity;
- what it is about: the run as a whole, or one part of the output by id.

**Grounding.** A judgement of the person's kind rests on a reference entry: the entry applies
when the run shows the same fault through the same kind of fact, at the same size or worse. A
failed test or gate, and a code review, ground themselves. No ground, no finding. Most runs give
few findings, and none is a whole answer.

The prompt is `prompts/run-reviewer.txt`.

## Proposal reviewer (step 3, plan: review)

**Job.** Reviews the proposals at the top of the planner's order, and gives textual feedback and
numerical corrections. The reviews go back to the planner. The loop ends when further review can
no longer materially change the top proposals.

**Inputs.** The proposals, M.p.v, this method, and the findings each proposal answers.

**Outputs.** For each proposal: feedback in words; corrections to its numbers (gain, cost,
confidence); and a recommended disposition, approve, postpone or reject. The reviewer
recommends; it does not filter. Every proposal the planner has not withdrawn reaches the
decision maker, with its reviews and a summary of where the reviewers disagree.

**Grounding.** Each point names what it checks against: a section of M.p, a rule of this method,
a finding, or a reference entry. The checks are consistency with M.p and with the method, and a
check in the proposal that can decide it (Spec Kit's analyze; Google design review). Heavy review
is kept for changes that are hard to undo (Amazon's Type 1 decisions).

## Code reviewer (step 6, code review)

**Job.** Reviews the diff before release, and either accepts the code or sends the code back to
the coder with the review. Either way the review is written down, and step 1 reads it.

**Inputs.** The diff, the change request it implements, the delta to M.p, and the results of the
change's gates.

**Outputs.** Accept, or request changes, with the review's comments, each tied to lines of the
diff.

**Grounding.** Each comment names the rule it applies: the change's spec, a mantra or habit of
this method, or a reference entry. The code reviewer is a ready-made code-review agent,
configured with this method and the person's examples (survey-ready-made-reviewers).

## How the reviewers learn from the person's data

All three follow one path, in the order the evidence supports (survey-simulated-reviewer).

1. **Measure first.** Hold out items. Score each reviewer by Cohen's kappa against the person,
   not by percent agreement. Re-ask the person 20 to 30 old items blind, weeks later, to get the
   person's own consistency, the ceiling. Published simulators of individuals reach 85% to 88%
   of that ceiling.
2. **A few dozen items: show them all, with the person's reasons.** When the examples fit in
   context, all of them go in. They are not sorted by label. Each carries the person's short
   reason. Rejected items stay, marked as rejected.
3. **Decide only when sure.** Run the reviewer several times with different subsets of the
   examples; their agreement is the confidence. Below a threshold set on held-out items, the
   reviewer stays silent or hands the item to the person. Start with high precision.
4. **30 to 100 items: distil readable rules,** kept beside the examples. A rule is kept only if
   it raises held-out agreement or holds across several of the person's items. Free-text
   critiques are grouped into named kinds of fault, each with a definition and examples
   (AutoLibra), and the items no kind explains are listed.
5. **Choose what to ask the person next** by coverage and disagreement: the items the reviewer
   escalates, plus a few random items to keep the agreement number honest.
6. **50 to 300 items: optimise the prompt offline** on the person's labels, with train and
   held-out split by time (GEPA, MIPROv2).
7. **Hundreds of items, and only if the steps above plateau below the ceiling:** a LoRA on a
   smaller judge, with old examples replayed.
8. **Throughout: keep the examples current.** Retire superseded items explicitly, weight recent
   items more, and recalibrate the threshold on the newest items.

The person's approvals and rejections of each review feed back as new entries. A kind of comment
the person keeps turning down is switched off (Google AutoCommenter).

## Sources

`survey/survey-simulated-reviewer.md`, `survey/survey-ready-made-reviewers.md` and
`survey/survey-improvement-step.md` in the repository `shared`.

## Metadata

- Which ready-made agent serves as the code reviewer is an open decision. PR-Agent is the
  candidate.
