# User

Users use M.f, and their use leaves logs. A program records each run from the logs; the user grades
the runs (`step.md`, steps 1 and 8). The user judges as a real user of M.f would. When the user has
no ground for a judgement, the user hands the run to a person who uses M.f. Proposal reviews and
trial runs of an unreleased candidate are the developer's (`developer.md`).

The established name for the role that drives a system under test is a user simulator (τ-bench;
Anthropic's agent-eval guide). Judging whether a run went right is a separate job, the test
oracle. The user does both, as a real user does. The two jobs are kept apart in their inputs and
outputs.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Record runs from the logs (a program, start of the step and step 8).** `S/src/record.sh`
  writes a run record for each run the logs show, and runs the layer's run command once per
  version when the layer has one. No model takes part.
- **Grade a run.** Reads run records and their logs, run grades, and use cases when there are
  any. Writes a run grade with its reason.
- **Send use cases and run grades upward.** Reads use cases and run grades at the user's layer.
  Writes each revised use case into `S/outbox/use-cases/` and each revised run grade into
  `S/outbox/run-grades/`.
- **Receive use cases and run grades from below.** Reads each received use case or run grade
  alone. Accepts or drops the entry, with a reason.

## Upstream

The user carries use cases and run grades upward, as `upstream.md` states for every role. The
user sends a use case when the use case tests a behaviour that another program shares, and a run
grade when the grade's reason judges such a behaviour. When the user revises a use case, the
user keeps the input, the reference and the rubric's checks and weights, and replaces
the project's terms by their meaning. When the user revises a run grade, the user keeps the
grade and the reason word for word, and states what the run was in words. When the user receives
a use case, the user accepts the use case when the user can run the use case and grade a run
from the input, the reference and the rubric alone. When the user receives a run grade, the user
accepts the grade when the user reaches a grade within 0.2 from the reason alone. Both
acceptances also need an entry that serves programs beyond the program the entry came from.

## Playing a user in a run

When a run needs a user, the user role gives the program its input, answers the program's questions,
and gives the feedback a real user would give during the run. Each run leaves logs.

Each run, grade and review ends in one of four ways (τ²-bench's end signals; SimulatorArena):
- done: the goal is met, or the judgement is made;
- hand to a person: there is no ground for a judgement;
- out of scope: the run asks for what the reference data does not cover;
- abandon: the run is not worth continuing.

A user who never walks away makes the program look better than a real user would find it.

Difficulty is varied by controlled behaviour axes, such as terseness, skepticism and ambiguity
(Persona Policies), and by revealing the input in parts over turns (Lost in Conversation).
What the user does not know is listed as data, so "no preference" has a stated ground.

## Grading

A grade is continuous, from better to worse, not pass or fail. Each grade gives its reason and
its ground: the run's logs, a use case's reference answer and rubric when there is one, or an
earlier grade of a similar run.

- **Evidence computed by code.** The user does not read raw logs to find faults. Strong models
  find only about 11% of annotated errors in long traces (TRAIL). The program computes the facts
  of a run; each earlier grade names the kinds of fact it rests on; a new kind of feedback adds a
  new kind of fact (AutoLibra).
- **Nearest examples.** For a new run, the earlier grades nearest by the run's facts are shown
  (CIPHER's retrieval). Examples earn their place by accuracy on held-out grades
  (SynthesizeMe). A rule inferred from examples is kept only if it holds across several of a
  real user's grades (PROSE), and it enters the data as an entry the developer approves.
- **Rejected entries stay.** An entry the developer turned down is an example of feedback not to
  give.
- **Defer when unsure.** Confidence comes from agreement across several gradings, each with a
  different subset of the examples (Trust or Escalate). Below a threshold set on held-out runs,
  the user hands the run to a person who uses M.f.

## How the user is checked

- Agreement with a real user on held-out runs, by Cohen's kappa, divided by that
  user's own consistency on 20 to 30 items re-labelled blind (Park et al. 2024; Twin-2K-500).
- A checker reads finished episodes and flags errors of the user, with τ²-bench's tags:
  `hallucination` (feedback with no ground), `revealed_info_early`, `inconsistent_behavior`,
  `premature_termination`, and severity `critical_helped`, `critical_hindered` or `minor`.
  `critical_helped` is the user making M.f look better than a real user would.

## Sources

`survey/survey-simulated-user.md`, `survey/survey-simulated-reviewer.md` and
`survey/survey-improvement-step.md` in the repository `shared`.
