# User

The user runs M.f on use cases, grades the runs, and reviews proposals at step 4 of the step
(`step.md`). The user judges as the person would. When the user has no ground for a judgement,
the user hands the use case to the person.

The established name for the role that drives a system under test is a user simulator (τ-bench;
Anthropic's agent-eval guide). Judging whether a run went right is a separate job, the test
oracle. The user does both, as the person does. The two jobs are kept apart in their inputs and
outputs.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Run M.f side by side, v and v+1 (step 5).** Reads use cases. Runs the current v and the
  candidate v+1 on the same use cases. Writes run records.
- **Run M.f after a release.** Reads use cases. Writes run records.
- **Grade a run.** Reads use cases, run records and run grades. Writes a run grade with its
  reason.
- **Review proposals (step 4).** Reads run reviews, proposals, proposal reviews and decisions.
  Writes proposal reviews.
- **Give feedback and corrections (step 4).** Reads proposals, proposal reviews and decisions.
  Writes proposal reviews: textual feedback and numerical corrections.

## Running a use case

The user gives the use case's seed, answers the program's questions, and gives the feedback the
person would give during the run. Each run leaves a run record.

Each run, grade and review ends in one of four ways (τ²-bench's end signals; SimulatorArena):
- done: the goal is met, or the judgement is made;
- hand to the person: there is no ground for a judgement;
- out of scope: the use case asks for what the reference data does not cover;
- abandon: the run is not worth continuing.

A user who never walks away makes the program look better than the person would find it.

Difficulty is varied by controlled behaviour axes, such as terseness, skepticism and ambiguity
(Persona Policies), and by revealing the use case in parts over turns (Lost in Conversation).
What the user does not know is listed as data, so "no preference" has a stated ground.

## Grading

A grade is continuous, from better to worse, not pass or fail. Each grade gives its reason and
its ground: the use case's reference answer and rubric, or an earlier grade of a similar run.

- **Evidence computed by code.** The user does not read raw logs to find faults. Strong models
  find only about 11% of annotated errors in long traces (TRAIL). The program computes the facts
  of a run; each earlier grade names the kinds of fact it rests on; a new kind of feedback adds a
  new kind of fact (AutoLibra).
- **Nearest examples.** For a new run, the earlier grades nearest by the run's facts are shown
  (CIPHER's retrieval). Examples earn their place by accuracy on held-out grades
  (SynthesizeMe). A rule inferred from examples is kept only if it holds across several of the
  person's grades (PROSE), and it enters the data as an entry the person approves.
- **Rejected entries stay.** An entry the person turned down is an example of feedback not to
  give.
- **Defer when unsure.** Confidence comes from agreement across several gradings, each with a
  different subset of the examples (Trust or Escalate). Below a threshold set on held-out runs,
  the user hands the run to the person.

## How the user is checked

- Agreement with the person on held-out runs and decisions, by Cohen's kappa, divided by the
  person's own consistency on 20 to 30 items re-labelled blind (Park et al. 2024; Twin-2K-500).
- Whether the user ranks two versions of M.f the way the person does.
- A checker reads finished episodes and flags errors of the user, with τ²-bench's tags:
  `hallucination` (feedback with no ground), `revealed_info_early`, `inconsistent_behavior`,
  `premature_termination`, and severity `critical_helped`, `critical_hindered` or `minor`.
  `critical_helped` is the user making M.f look better than the person would.

## Sources

`survey/survey-simulated-user.md`, `survey/survey-simulated-reviewer.md` and
`survey/survey-improvement-step.md` in the repository `shared`.
