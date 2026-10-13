# One step of S

How a change is made, checked and recorded. The step holds for every project that S serves.

## Terms

- **The person** directs a project. The person says what the person wants, and then labels:
  the person grades runs, gives feedback with reasons, and approves or turns down proposals and
  releases.
- **M** is a project. M holds a plan, M.p, and a prototype, M.f. M.p is the specification of
  M.f.
- **S** is the development system. S builds, reviews and improves M. S also improves S's own
  parts: these specs, the agents that play the roles, and the project's data.
- **A generation** is a major iteration of M, such as the fifth rebuild of a prototype. A
  generation n has versions n.0, n.1, and so on (`versioning.md`).
- **A version** v is one state of M.p and M.f. A step of S moves M from v to v+1.
- **A run** is one execution of M.f on one use case. Each run leaves a run record.

## Roles

A role is defined by its actions. The roles are the user (`user.md`), the decision maker
(`decision-maker.md`), the run reviewer (`run-reviewer.md`), the planner (`planner.md`), the
proposal reviewer (`proposal-reviewer.md`), the coder (`coder.md`) and the code reviewer
(`code-reviewer.md`). Any role may be played by a person, an AI or a program. One role may be
played by several players at once; for instance, an AI may play the user first and a person on
top.

No role reviews an artifact it wrote. (ITIL's standard change; DORA on change approval.)

The data each action reads and writes is described in `data.md`.

## Changes, their kinds and their checks

Every change to M.f's behaviour is made in M.p first, then in M.f. M.p is reviewed before M.f
is built from it.

A change to M.p is written as a delta: what the change adds, modifies or removes. The delta
merges into M.p when the change is released. (OpenSpec, Spec Kit, Kiro.)

Each change carries a kind. The kinds are the Conventional Commits types `feat`, `fix`,
`refactor`, `perf`, `docs`, `test`, `build`, and `!` for a breaking change, plus `instr`.
`instr`, instrumentation, is an adjustment to logging and measurement. Instrumentation is a kind
of its own in gitmoji, and OpenTelemetry treats emitted signals as a public interface. The short
name `instr` is ours.

An alternative path built beside the existing one, for comparison or for a gradual transition,
is a technique inside another kind, not a kind of its own. (GitHub's Scientist, branch by
abstraction, strangler fig, parallel change, canarying.)

Each kind brings its own check. Every number in a check comes from a source or is written in
the proposal before the run.

- **`fix`:** at least one test fails on v and passes on v+1, and every test that passed on v
  still passes. (SWE-bench's FAIL_TO_PASS and PASS_TO_PASS.)
- **`refactor`:** every test that passed still passes, and no existing test is edited. Where
  tests are missing, characterization tests are added first.
- **`perf`:** the refactor check, plus at least 10 interleaved runs before and after, with the
  count fixed in advance. The gain counts only if a Mann-Whitney U test gives p < 0.05 and the
  change lies outside the noise band (±2% by default). A profile names the limiting factor.
  (benchstat, criterion, Google Benchmark.)
- **`instr`:** behaviour is unchanged, as for a refactor. Each signal the proposal declares
  appears in the run record. Renaming or removing a signal someone reads makes the change
  breaking. (OpenTelemetry.)
- **A prompt change:** a case counts as passing on v only if the case passed in all k trials,
  with k set in the proposal, and every such case passes on v+1. Versions are compared by
  paired differences on the same use cases. (Anthropic's eval guidance; the exact pass rule is
  ours.)
- **A change using an alternative path** adds three checks to its kind's own. With the switch
  off, nothing changes. Both paths run on the same use cases, with success and failure conditions
  written before the run. The removal of the losing path is planned, with a date.


## The step, from v to v+1

A step follows the DevOps loop (plan, code, build, test, release, deploy, operate, monitor),
entered at monitor, because S's proposals come from what the runs show.

Runs come from several drivers: CI/CD tests, developers running M.f on purpose, real users, and
the user role. Tests decide right or wrong, and so yield scores automatically. The user role
gives continuous grades, sometimes without running the program at all (τ-bench; Anthropic's
agent-eval guide). Runs before or after a release are not guaranteed: the loop works with
whatever runs exist, and with none.

1. **Monitor: review.** The run reviewer reads the run records, if there are any, and the code
   reviews of step 6 in any case. The run reviewer writes findings, the areas to improve. Each
   finding names the symptom it rests on, in the run records or the code reviews, and, where one
   exists, the reference the symptom is judged against. The run reviewer grades each finding by
   severity, and the finding enters the backlog.
2. **Plan: propose.** From the findings, the planner writes change proposals. Each proposal
   states the gain, the delta to M.p.v, the kind, the design, the tasks and the check. The
   planner quantifies each proposal's upsides and downsides side by side, and orders the
   proposals by weighing them. The order is the planner's alone. The planner does not write
   proposals too slight to matter.
3. **Plan: review.** The proposal reviewer reviews the proposals at the top of the order, and
   gives textual feedback and numerical corrections. The reviews go back to the planner, who
   revises the proposals: a propose-review loop. The loop ends when further review can no
   longer materially change the top proposals. (Rust RFCs, Google design docs, KEPs with
   reviewers distinct from authors, PEP 1, Amazon's Type 1 and Type 2 decisions.)
4. **Plan: decide.** The reviewed proposals reach the user and the decision maker. The user
   reviews them and gives feedback and numerical corrections. The feedback and corrections send
   the proposals back to the planner at step 2: a propose-review-decide loop. To end the loop,
   the decision maker approves some proposals as change requests for step 5. The feedback,
   corrections and decisions are kept as data. (Rust, PEP 1, HashiCorp RFCs.)
5. **Code, build and test.** The coder writes the change requests on a branch, in order. Each
   change request passes its gates, the checks of its kind, or is abandoned. Changes that pass
   join a merge queue. A change that fails drops out, and the coder logs the reason. When the
   user runs the candidate v+1 and the current v side by side on the same use cases, code
   scores the difference on metrics fixed before the run. (GitHub required checks and merge
   queue; Software Engineering at Google; Google SRE canarying; Spinnaker Kayenta.)
6. **Code review.** A gate before release. The code reviewer reviews the diff and either accepts
   the code or sends the code back to the coder with the review. Either way the code reviewer
   writes the review down, and the run reviewer reads it at step 1. (Google code review;
   GitHub's required review, approve or request changes.)
7. **Release and deploy, to developers.** The decision maker releases v+1 or keeps v, with the
   code review in hand, and with the graded runs of the side-by-side comparison when there are
   any. The coder then merges each released change into the branch the step started on, from
   the merge queue; a kept change stays on its branch. A release that proves worse is reverted.
   Any runs go on to step 1. (Software
   Engineering at Google; LLVM; feature toggles; DORA on change approval.)

A release goes to developers. A released M.f is expected to be fit for developers' runs.

Runs after a release, by real users, developers, the user role or automation, on use cases
inside or outside M's dataset, may happen at any time. Their records go to step 1.

## Runs inside a step

A step starts with the use cases it can run. The user writes a use case for each behaviour M.p
states that no use case covers yet, and runs the current version on each use case that has no
run record of it. So a step that starts with no data, as the first step on a project developed
by other means does, still gives the run reviewer runs to read.

Inside the step, a step may include runs at two more points, and may include none.

- **Before release, trial runs.** After the coder's step 5, a simulated developer (the user role)
  or the person makes one or more trial runs of the candidate v+1, side by side with v when both
  can run. A trial run logs more than a true run: the run sets `S_RUN_KIND=trial`, and M.f
  raises its logging when it sees it.
- **After release, trial runs or true runs.** After step 7, simulated users (the user role) or
  real users run v+1. The user role grades the runs it makes.

Each run leaves a run record in `S/data/run-records/`, and the run reviewer reads it at the next
step 1. A layer that has no way to run M.f yet leaves its run command empty, and its steps include
no runs.

## Triggering and chaining

A chain is the order of the step's hand-offs. At each hand-off, the role that finishes writes its
entries into the layer's `S/data/<type>/`, and the next role takes them from there.

| Step | Role | Writes | Next |
|---|---|---|---|
| use cases | user | use cases | the user, for runs |
| runs | user | run records, run grades | run reviewer |
| 1. monitor | run reviewer | run reviews | planner |
| 2. propose | planner | proposals | proposal reviewer |
| 3. review | proposal reviewer | proposal reviews | planner, until the loop ends; then the user |
| 4. decide | user, then decision maker | proposal reviews, then decisions | coder |
| 5. code | coder | the change, and its gates' results in the step's log | the user, for trial runs, or the code reviewer |
| trial runs | user | run records, run grades | code reviewer |
| 6. code review | code reviewer | code reviews | decision maker |
| 7. release | decision maker | a release decision | coder |
| merge | coder | the merge, in the step's log | the user, for runs after release, or the next step's run reviewer |
| runs after release | user | run records, run grades | the next step's run reviewer |

Each hand-off starts in one of two ways:
- **automatically**, when the previous role's entries arrive;
- **by a person**, who reads the entries, and starts the next role by hand. A person can also
  play the role, writing the entries in the role's place.

`S/src/chain.json` holds the layer's chain: each hand-off, its role, what the role writes, how
the hand-off starts, how many rounds the propose-review loop may take, the layer's run command,
and the leg to the layer above. `S/src/step.sh <layer root>` plays the chain. It gives each role
its prompt, its settings and the step so far, records each hand-off in the step's log
`S/steps/<step id>/`, and stops where a hand-off waits for a person. `step.sh <layer root>
--from <hand-off>` resumes there. When a role writes an entry tagged `"upstream": "candidate"`,
`step.sh` has the same role's sending agent revise the entry into `S/outbox/<type>/`
(`upstream.md`).

`shared` gives the default chain. A project or a component customises its own `chain.json`:
which hand-offs start automatically, which wait for a person, which runs a step includes. A layer
can close the loop fully, or leave some hand-offs to a person. (GitHub Actions'
`workflow_dispatch` beside event triggers; manual approval gates in CI/CD pipelines.)

## Retrospective and curation

Two activities sit beside the loop rather than in its sequence. Each is placed where its input
appears.

- **Retrospective** looks at how S itself worked: which findings, proposals, reviews and checks
  helped, and which cost time and gave nothing. S holds one retrospective per loop, after
  monitor, and a postmortem at once after a release that proves worse. The retrospective's
  changes to S are changes like any other. (Scrum; Google SRE.)
- **Curation** keeps the labels that prove useful. Grades, feedback and priority orders that
  hold beyond the run or the step they were given in become reference data, off the critical
  path. (LangSmith and Langfuse datasets.)

## The run record

Each run record holds:
- the versions of M and S;
- the settings;
- the use case;
- the trace: every model call and tool call the run made, each with its start, end, inputs and
  outputs, nested under the call that started it (OpenTelemetry's spans);
- the outcome;
- the grades, and who gave each;
- time, tokens and cost.

(MLflow runs, OpenTelemetry's GenAI agent spans, SLSA provenance, and Anthropic's split between
transcript and outcome.)


The format of the run record, and of the other data, is in `data.md`.

## Sources

The surveys in `survey/` of the repository `shared`: `survey-development-flow.md`,
`survey-change-kinds.md`, `survey-improvement-step.md` and `survey-process-terms.md`.
