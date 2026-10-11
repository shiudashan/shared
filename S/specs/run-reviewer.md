# Run reviewer

The run reviewer judges runs at step 1 of the step (`step.md`), monitor. The run reviewer reads
the run records, if there are any, and the code reviews of step 6 in any case, and writes
findings: the areas to improve. A finding is a run review (`data.md`).

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Read run records (step 1).** Reads run records.
- **Read code reviews (step 1).** Reads code reviews.
- **Write a finding with its symptom (step 1).** Reads run records, run grades and run reviews.
  Writes a run review: the finding and the symptom it rests on.
- **Name the reference a symptom is judged against (step 1).** Reads use cases.
- **Grade a finding by severity (step 1).** Reads run grades, run reviews and decisions. Writes
  the severity into the run review.

## Findings

Each finding names:
- the symptom it rests on, in a run record or a code review;
- the reference it is judged against, where one exists: a use case's reference answer or
  rubric, an earlier run review the person approved, a test, or a gate;
- its severity;
- what it is about: the run as a whole, or one part of the output by id.

**Grounding.** A judgement of the person's kind rests on a reference: an earlier run review
applies when the run shows the same fault through the same kind of fact, at the same size or
worse. A failed test or gate, and a code review, ground themselves. No ground, no finding. Most
runs give few findings, and none is a whole answer.

The run reviewer reads the run's facts as the program computes them, and the log lines they rest
on, each labelled with its kind of fact. It does not search raw traces for faults (TRAIL).

## How the run reviewer learns from the person's data

The run reviewer, the proposal reviewer and the code reviewer follow one path, in the order the
evidence supports (survey-simulated-reviewer).

1. **Measure first.** Hold out items. Score the reviewer by Cohen's kappa against the person,
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

`survey/survey-simulated-reviewer.md` and `survey/survey-improvement-step.md` in the repository
`shared`.
