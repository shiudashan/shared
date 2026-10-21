# One step of S

How a change is made, checked and recorded. The step holds for every project that S serves.

## Terms

- **The user** takes a released version of M.f and uses it: gives it seeds, answers its
  questions, gives feedback during a run, and grades runs. A grade with its reason is how the
  user reports a bug.
- **The developer** develops M through S: ranks the bugs, features and refactors, reviews the
  proposals, makes trial runs of the unreleased candidate, and approves or turns down proposals
  and releases.
- **M** is a project. M holds a plan, M.p, and a prototype, M.f. M.p is the specification of
  M.f.
- **S** is the development system. S builds, reviews and improves M. S also improves S's own
  parts: these specs, the agents that play the roles, and the project's data.
- **A generation** is a major iteration of M, such as the fifth rebuild of a prototype. A
  generation n has versions n.0, n.1, and so on (`versioning.md`).
- **A version** v is one state of M.p and M.f. A step of S moves M from v to v+1.
- **A run** is one execution of M.f on one use case. Each run leaves a run record.

## Roles

A role is defined by its actions. The roles are the user (`user.md`), the developer
(`developer.md`), the decision maker (`decision-maker.md`), the run reviewer (`run-reviewer.md`),
the planner (`planner.md`), the proposal reviewer (`proposal-reviewer.md`), the coder (`coder.md`)
and the code reviewer (`code-reviewer.md`). Any role may be played by a person, an AI or a program.
One role may be played by several players at once; for instance, an AI may play the developer first
and the person who develops M on top (Developer mode).

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

Each check is written in the proposal as gates. A gate is a command when a program can do the
check: the command exits 0 only when the check passes, with every number of the check built in.
When a program cannot do the check, the gate is a prompt: what a model must check, reading only
the logs and the source. The coder runs each command gate through `S/src/gate-run.sh`, which runs
it once and records the run: the command, the commit and its tree, whether the work tree was
clean, and the exit code. After step 5 the program decides each command gate from those records
alone, and reruns nothing: a gate passes when its latest record ran the proposal's command, on a
clean tree holding the change's commit, and exited 0. The code reviewer judges each prompt gate at
step 6, and the program checks that every prompt gate has a passing verdict. The program decides
where it can, and a model decides only the rest. A change with no gates fails: a gate that passes
because nothing ran is not a pass.

A change may defer the tests of its check. In RSI the design changes often from step to step,
so complete tests for a design that is about to change can be wasted work. The coder lists each
deferred test, with a priority, in the step's reply and in the change's commit message. At the
next step 1 the run reviewer writes each open deferred test as a finding, and the planner
schedules it with the other work. All tests should be complete at release; a release with open
tests says so (step 7).


## The step, from v to v+1

A step follows the DevOps loop (plan, code, build, test, release, deploy, operate, monitor),
entered at monitor, because S's proposals come from what the runs show.

Runs come from several drivers: CI/CD tests, developers running a candidate on purpose, real
users, and the user role. Tests decide right or wrong, and so yield scores automatically. The user
role gives continuous grades, sometimes without running the program at all (τ-bench; Anthropic's
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
4. **Plan: decide.** The reviewed proposals reach the developer and the decision maker. The
   developer reviews them and gives feedback and numerical corrections. The feedback and corrections
   send the proposals back to the planner at step 2: a propose-review-decide loop. To end the loop,
   the decision maker approves some proposals as change requests for step 5. The feedback,
   corrections and decisions are kept as data. (Rust, PEP 1, HashiCorp RFCs.)
5. **Code, build and test.** The coder writes the change requests on a branch, in order. Each
   change request passes its gates, the checks of its kind, as the program decides them from the
   gate records, or is abandoned. Changes that pass
   join a merge queue. A change that fails drops out, and the coder logs the reason. When the
   developer runs the candidate v+1 and the current v side by side on the same use cases, code
   scores the difference on metrics fixed before the run. (GitHub required checks and merge
   queue; Software Engineering at Google; Google SRE canarying; Spinnaker Kayenta.)
6. **Code review.** A gate before release. The code reviewer reviews the diff and either accepts
   the code or sends the code back to the coder with the review. Either way the code reviewer
   writes the review down, and the run reviewer reads it at step 1. (Google code review;
   GitHub's required review, approve or request changes.)
7. **Release.**
   1. **The decision maker chooses** between the version in use now and the new version with
      this step's changes, with the code review, the trial runs and the list of open deferred
      tests in hand. A release with open tests names them in the release decision.
      - When the decision maker chooses the new version, the coder adds this step's changes to
        the branch the step started from. A change that failed a gate is never added; the
        program checks the branch after the merge and stops the step if one was.
      - When the decision maker keeps the version in use, the coder leaves this step's changes
        on their own branches and adds nothing.
      - When a released version later proves worse than the one before it, the decision maker
        takes the release back, and the coder removes its changes.
   2. **Then the decision maker decides whether to pick up any remaining open finding.**
      - When the decision maker picks up one or more findings, the step returns to step 2,
        propose, with those findings alone, building on the version chosen in 1. When that work
        reaches step 7 again, the decision maker decides again.
      - When the decision maker picks up none, that one decision accepts every remaining open
        finding as a known defect, and the version chosen in 1 is released to users, with
        those defects.

   (Software Engineering at Google; LLVM; feature toggles; DORA on change approval.)
8. **Use case.** After the release, the user runs the version in use on a new use case, one
   different from the earlier ones. Open findings do not hold this back. Steps of S alternate in
   this way between the design and new use cases: a new use case shows parts the design must add,
   parts it can remove, and existing parts it can use again. The new case is a seed a user gave
   that no run has used yet. When there is none, the step stops and asks for one. The
   run records go to the next step 1.

About releases:
- A release goes to users, and a released version is one that users can run.
- Users, the user role, developers or automated tests may run a released version at any time.
  The run reviewer reads the records of those runs at the start of the next step of S.

## Runs inside a step

A step starts with the use cases it can run. The user writes a use case for each behaviour M.p
states that no use case covers yet, and runs the current version on each use case that has no
run record of it. So a step that starts with no data, as the first step on a project developed
by other means does, still gives the run reviewer runs to read.

Inside the step, a step may include trial runs, and may include none. After the coder's step 5, the
developer makes one or more trial runs of the candidate v+1, side by side with v when both can run.
A trial run logs more than a true run: the run sets `S_RUN_KIND=trial`, and M.f raises its logging
when it sees it. Runs of a released version belong to the next step, which starts by running the
version in use.

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
| 3. review | proposal reviewer | proposal reviews | planner, until the loop ends; then the developer |
| 4. decide | developer, then decision maker | proposal reviews, then decisions | coder |
| 5. code | coder | the change, and its gates' results in the step's log | the developer, for trial runs, or the code reviewer |
| trial runs | developer | run records, run grades | code reviewer |
| 6. code review | code reviewer | code reviews | decision maker |
| 7. release | decision maker | a release decision | coder |
| merge | coder | the merge, in the step's log | decision maker |
| pick up | decision maker | the findings picked up, or none | the planner, with those findings, or the user |
| 8. use case | user | a use case, run records, run grades | the step's end |

A hand-off may name the types it needs. `step.sh` skips the hand-off when none of those types
gained an entry earlier in the same step: the planner proposes only from new findings, and the
coder codes only after new decisions. A step that finds nothing new ends after monitor, at the
cost of the runs and monitor alone.

## Developer mode

The person who develops the project plays the developer, and works with S step by step, the way
a user works with M.f round by round. At the end of each of S's steps that the developer is
consulted on, S shows the step's work in the developer's terms: the findings with their evidence;
the proposals in order, with their gains, costs and checks and the reviewer's corrections; the
decisions with their reasons; each change with its tests and trial runs; the code review; the
release. The developer answers in words. The answer goes into the step: agreement passes the
step's entries on, and any direction in it goes to the next role; a correction has the step done
again with the developer's words in hand; the developer's own content, such as a finding or a
decision, becomes an entry, by the developer. The developer's words are kept verbatim, in the
entries (`status`, `decided`, `reason`, and `earlier` for an edited entry, `data.md`) and in the
step's log, so they travel upward like any other entry.

The developer is consulted at the end of each step listed in `chain.json`'s `consult`: by default
steps 1, 3 (propose and review, shown together), 4, 5, 6, 7 and 8. The hand-offs that only record,
the user's seed as a use case and the user's runs, need no consultation. When a step no longer needs
the developer, the developer takes it out of `consult`, and its work is shown with the next
consulted step. (Interrupt and resume in human-in-the-loop agent frameworks, such as LangGraph;
levels of automation, Sheridan and Verplank, and Parasuraman, Sheridan and Wickens 2000.)

A Claude Code session runs S with the developer (the skill `run-s`). It plays the steps with
`step.sh`, shows each consulted step's work, and records the developer's answer with
`S/src/gate.sh <layer root> approve | edit | reject | takeover "<the developer's words>"`. A hook
puts where the step stands beside each of the developer's messages, so the session works from the
step's state, not from the chat. Each role also names, in its reply, the entries it relied on, and
the step's log keeps them.

Every message to a role starts with the global prompt, `S/src/agents/global.md`: the rules every
role shares, such as how RSI differs from the maintenance of a live website. The role's own
`prompt.md` follows, then the task. A rule that holds for every role is written in the global
prompt alone, not in the role prompts (`habits.md`, one rule per decision).

`S/src/chain.json` holds the layer's chain: each hand-off, its role, what the role writes, how
the hand-off starts, how many rounds the propose-review loop may take, the layer's run command,
and the leg to the layer above. `S/src/step.sh <layer root>` plays the chain. It gives each role
its prompt, its settings and the step so far, records each hand-off in the step's log
`S/steps/<step id>/`, and stops at the end of each consulted step. `step.sh <layer root>
--from <hand-off>` resumes there. When a role writes an entry tagged `"upstream": "candidate"`,
`step.sh` has the same role's sending agent revise the entry into `S/outbox/<type>/`
(`upstream.md`).

When the step completes, `step.sh` holds the submit pass: each role that wrote entries in the
step tags them again with the whole step in view, and sends each candidate through its section
"Send" into `S/outbox/<type>/` (`upstream.md`). The coder offers its reusable programs.

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
