# Simulated user

The simulated user stands in for the person. It drives M.f on items from M's dataset, grades
each run, and reviews proposals and releases before the person does. When it has no ground for
a judgement, it hands the item to the person.

The established name for the role that drives the system is a user simulator (τ-bench;
Anthropic's agent-eval guide). Judging whether a run went right is a separate job, the test
oracle. The simulated user does both, as the person does; the two jobs are kept apart in its
inputs and outputs.

## Its jobs in the loop

- **Drive runs.** The simulated user draws items from M's dataset and plays the person's part
  in each run: it gives the item, answers the program's questions, and gives the feedback the
  person would give during the run. Each run leaves a run record (`method.md`, the run record).
- **Grade runs.** For each finished run, the simulated user gives a grade and its reason. The
  grade is continuous, not pass or fail.
- **Review at step 4.** The simulated user reviews the reviewed proposals before the person, with
  textual feedback and numerical corrections, and may approve some as change requests.
- **Release at step 7.** The simulated user decides first whether to release v+1 or keep v. The
  person, when present, decides on top.

## Inputs

- For a run: the item, the program's messages, and the person's reference data that applies.
- For a grade: the run's facts as the program computes them, the log lines they rest on, and the
  reference entries most similar to the run.
- For step 4: the proposals, their reviews, and the planner's order.
- For step 7: the code review, and the graded runs of the side-by-side comparison when there are
  any.

## Outputs

- Run records, through the runs it drives.
- Grades, each with its reason and its ground: the reference entry it rests on.
- At step 4 and step 7: decisions, feedback and corrections, each marked as given by the
  simulated user.
- Escalations: items it hands to the person, with the reason it could not decide.

Each output ends in one of four ways (τ²-bench's end signals; SimulatorArena):
- done: the goal is met, or the decision is made;
- hand to the person: there is no ground for a judgement;
- out of scope: the item asks for what the person's data does not cover;
- abandon: the run is not worth continuing.

A simulator that never walks away makes the program look better than the person would find it.

## Message shape

One general guidelines prompt, plus a block per episode that holds everything specific to it:
the item, what the simulated user knows, what it does not know, and its instructions
(τ²-bench's scenario). What the person does not know is listed as data, so "no preference" has
a stated ground.

Difficulty is varied by controlled behaviour axes, such as terseness, skepticism and ambiguity,
appended as a short block (Persona Policies), and by revealing the item in parts over turns
(Lost in Conversation).

## How it learns from the person's data

The model stays frozen. What changes is which of the person's examples the simulated user is
shown, and the readable rules distilled from them.

- **Learning from pairs.** Each reference entry is one pair: the evidence a run showed, and the
  person's feedback with its reason. For a new run, the entries nearest by the run's facts are
  shown (CIPHER's retrieval). Entries earn their place by accuracy on held-out entries
  (SynthesizeMe). An inferred rule is kept only if it holds across several of the person's
  entries (PROSE), and it enters the data as an entry the person approves, not as an edit to
  the prompt.
- **Evidence computed by code.** The simulated user does not read raw logs to find faults.
  Strong models find only about 11% of annotated errors in long traces (TRAIL). The program
  computes the facts; each reference entry names the kinds of fact it rests on; a new kind of
  feedback adds a new kind of fact (AutoLibra).
- **Rejected entries stay.** An entry the person turned down is shown as feedback not to give.
- **Defer when unsure.** Confidence comes from agreement across several runs of the simulated
  user, each with a different subset of the examples (Trust or Escalate's simulated
  annotators). Below a threshold set on held-out items, the simulated user hands the item to
  the person.

## How it is checked

- Agreement with the person on held-out runs and decisions, by Cohen's kappa, divided by the
  person's own consistency on 20 to 30 items re-labelled blind (Park et al. 2024; Twin-2K-500).
- Whether it ranks two versions of M.f the way the person does.
- A checker of the simulator itself reads finished episodes and flags simulator errors, with
  τ²-bench's tags: `hallucination` (feedback with no ground), `revealed_info_early`,
  `inconsistent_behavior`, `premature_termination`, and severity `critical_helped`,
  `critical_hindered` or `minor`. `critical_helped` is the simulated user making M.f look better
  than the person would.

## Sources

`survey/survey-simulated-user.md`, `survey/survey-simulated-reviewer.md` and
`survey/survey-improvement-step.md` in the repository `shared`.
