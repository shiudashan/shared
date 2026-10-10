# Method

How a change is made, checked and recorded. The method holds for every project that the
development system S serves.

## Terms

- **The person** directs a project. The person says what the person wants, and then labels:
  the person grades runs, gives feedback with reasons, and approves or turns down proposals and
  releases.
- **M** is a project. M holds a plan, M.p, and a prototype, M.f. M.p is the specification of
  M.f.
- **S** is the development system. S builds, reviews and improves M. S also improves S's own
  parts. S's parts are this method, the simulated users (`simulated-user.md`), the automatic
  reviewers (`reviewers.md`), the automatic planner (`planner.md`), the automatic coder
  (`coder.md`), and the person's data. Each part may be a workflow, a prompt, or code.
- **A generation** is a major iteration of M, such as the fifth rebuild of a prototype. A
  generation n has versions n.0, n.1, and so on.
- **A version** v is one state of M.p and M.f. A step of S moves M from v to v+1.
- **A run** is one execution of M.f on one item. Each run leaves a run record.

## Layers

Each of S's parts exists in three layers. Each layer holds a whole working copy of the part,
customised for that layer, under the folder `S/`. The file names under `S/` are the same in
every layer, so the copies of one part can be compared line by line.

- **Pan-project:** `S/` in the repository `shared`, used by every project.
- **In-project:** `<project>/S/`. S creates it when a project starts, and it evolves with the
  project.
- **In-iteration:** `<project>/<generation>/S/`. S creates it when a generation starts, and it
  lasts only that generation.

Two workflows move content between the layers. Sync (`workflows/sync.md`) brings the layer above
into a layer. Upstream (`workflows/upstream.md`) carries a layer's edits that serve the layer
above up to it. Sync runs when a project or a generation starts. After that, upstream runs
periodically, followed at once by sync. The pinning follows git submodule practice: each layer
pins the commit of the layer above that it was last synced to.

## Mantras

How the person judges engineering work. Reviews of specs and code, including code assembled
from the work of several agents, use the mantras as criteria. A simulated reviewer of code is
built on the mantras, together with the person's examples of each.

The person's examples of each mantra, with the person's own words, are part of the person's
data. New examples are kept as the person gives them.

### Unify and simplify

One general path, grown to fit each new case. It pays most once we are sure enough of what we
want that several things we had to describe separately can be described together, in one
coherent and shorter way. Before that, separate descriptions are the honest state.

- When a new case behaves like the existing ones, widen the general path until the case is
  ordinary, rather than adding a branch beside it. When a case really is different, a branch is
  the right shape; keep it.
- The question for every branch: is the difference real, or did the branch appear because the
  general path was too narrow to absorb the case? Only the second kind goes.
- A branch of the second kind is cheap once and expensive forever: it behaves differently, is
  tested separately, and must be remembered. Widening the path is expensive once, and every case
  gains from it.
- Widening often means rewriting the general path, and the rewrite looks risky. The test is the
  next new case: if it needs no new branch, the rewrite was right.
- If widening is too hard right now, add the branch as a marked debt: say in the code why the
  path could not take the case, and record it with the postponed work. When a second case needs
  a branch for the same reason, widen the path then; two cases show its shape.
- Simplify removes code that does not need to exist, even when it does no harm. A guard against
  a failure that can really happen is needed, and stays.
- Unneeded branches often appear where a graded signal could do the job but was cut into yes/no
  cases. Let the score drive the one path.
- Words are paths too. Where a field already has a well-built term for a thing, use it rather
  than coining our own; invent a word only when none fits.

### Bugs indicate poor architecture

Instead of doing the locally right thing to quiet a bug, it is more rewarding to improve the
architecture, even if the bug is not fully closed for a while.

When a bug surfaces a more general issue, address the general issue, whether that makes the
bug's symptom better or worse for now.

Existing code is often an earlier, intentionally simpler implementation. When it runs into an
issue that was to be expected, rewrite it with a better, more thoughtful design, using the
hindsight. Everything improves, with no trade-off except perhaps more code, which is accepted.
This is not a design question for the person.

### Move hard-coded parameters into configuration

After hard-coding parameters to get a function working, consider moving them into
configuration objects.

## Habits

Gentle reminders for writing and reviewing specs and code. Following them is not mandatory;
departing from one is worth a sentence of reason.

### Making runs visible
1. When a run starts, show every parameter that changes its behaviour, once, in the terminal.
2. Log every call: what it was, when it ran, and how its time and tokens split, cached input and
   thinking included. Keep a full call-by-call profile of runs that matter.
3. Check the environment at start: the services a run needs answer, and vendored code holds
   exactly its patches. Stop with a plain message if not.

### Checks and limits
4. Check from where the thing is used: a page from the machine the person reads it on, a
   permission by an action that tries to cross it. A check that passes because nothing happened
   is not a pass.
5. Every limit has an enforcer in the program. A limit that only logs, or only asks the model to
   stop, is a wish.

### Specs and prompts
6. Change the spec first, then the code. Review the spec before code is built from it. A
   behaviour that lives only in code is lost at the next rebuild.
7. Keep content and metadata apart, in specs and in what the system itself writes and shows: what
   a thing is, separately from notes about it (what comes later, what was set aside, how the run
   is going, where an idea came from). Reasoning that explains the content is content.
8. One rule per decision, across all prompts. Two rules that pull against each other, or a
   question that carries its asker's own pick, cost thinking and give nothing.

### Shaping work
9. Ask for review before doing the work a decision governs, not after.
10. Keep the critical path short. Work nobody waits on runs in the background at lower priority.
11. Don't redo work whose inputs haven't changed.
12. Let the program do mechanical work and models do judgment.
13. Give an agent the inputs it needs in its message, and only those.
14. Choose each role's settings by its eval: its model, how much it thinks, and its step budget.

### Iterating
15. Keep a generation's cycle short: try it, close it with a lessons file, start the next.
16. Keep set-aside items in one circle-back file, each saying what was given up and when to
    return to it.
17. When a new generation replaces an old one, check behaviour by behaviour that what the old one
    did is kept or deliberately dropped.

### Data
18. Keep every word the person gives, with what it was about, as data, written as it is given.
    Never record words as the person's that the person did not give.

### Reproducibility
19. Keep every version rebuildable and every run traceable to the version that made it. Pin what
    the program depends on and check the pins at start. Give each change its own version: one
    commit holding its spec, code and tests, tagged, with a changelog entry. Record in each run
    the version and the settings it ran with.

## Building from a specification

A project is built from specifications: one for the system, and one for each component.

- **Specs come first.** A change in behaviour is made in its spec first, then in the code. If
  the code must behave in a way its spec does not allow, change the spec in the same commit and
  say so.
- **Read a spec generously.** If its words allow a behaviour, the behaviour is allowed. A general
  sentence names a set of acceptable designs; pick one. Read its words at the strength they are
  written: "usually" is not "always", and "can" is not "must".
- **Where it names a standard technique,** use it the way its usual libraries give it. Do not
  invent extra machinery around it.
- **Where it is silent, decide.** Different builds from one spec are expected to differ. Record
  each choice the spec left open in the project's `DECISIONS.md`, one line each: what was chosen
  and why, in a few words.
- **When how other software behaves matters, read its source.** Docs and source often disagree,
  and the source is what runs.
- **A limit of one build is not a hole in the spec.**
- **A rebuild reads the previous generation.** A new generation is built from its spec, and its
  builders read all of the previous generation's code as hindsight.

## Versioning

Each generation n of a project has versions n.0, n.1, n.2, and so on.

- **n.0** is the generation as it starts from the one before.
- **Each later version is one change.** It is one commit holding the change's spec, code and
  tests, tagged `<generation>.<k>` in git. So a past version can be rebuilt from its tag, and a
  change can be taken into another line on its own, by its commit.
- **`<generation>/VERSION`** holds the current version. A run prints it at start and records it
  in its run record.
- **`<generation>/CHANGELOG.md`** has one entry per version, newest last. Each entry names the
  commit of every change it lists.

An entry keeps two kinds of change apart:
- **In project:** the project's prototype, its specification, and its in-project and
  in-iteration S.
- **Cross project:** what serves every project. That is the pan-project S in `shared`, and the
  person's datasets.

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
  paired differences on the same items. (Anthropic's eval guidance; the exact pass rule is
  ours.)
- **A change using an alternative path** adds three checks to its kind's own. With the switch
  off, nothing changes. Both paths run on the same items, with success and failure conditions
  written before the run. The removal of the losing path is planned, with a date.

## One step of S, from v to v+1

A step follows the DevOps loop (plan, code, build, test, release, deploy, operate, monitor),
entered at monitor, because S's proposals come from what the runs show.

Runs come from several drivers: CI/CD tests, developers running M.f on purpose, real users, and
the simulated users. Tests decide right or wrong, and so yield scores automatically. Humans and
simulated humans, in the sense of τ-bench and Anthropic's agent-eval guide, give continuous
grades, sometimes without running the program at all. Runs before or after a release are not
guaranteed: the loop works with whatever runs exist, and with none.

1. **Monitor: review.** The run reviewer reads the run records, if there are any, and the code
   reviews of step 6 in any case. The run reviewer writes findings, the areas to improve. Each
   finding names the symptom it rests on, in the run records or the code reviews, and, where one
   exists, the reference the symptom is judged against. Each finding is graded by severity and
   enters the backlog.
2. **Plan: propose.** From the findings, the planner writes change proposals. Each proposal
   states the gain, the delta to M.p.v, the kind, the design, the tasks and the check. The
   planner quantifies each proposal's upsides and downsides, and orders the proposals by them;
   the order is the planner's alone. Proposals too slight to matter are not written.
3. **Plan: review.** The proposal reviewers, agents separate from the planner, review the
   proposals at the top of the order, and give textual feedback and numerical corrections. The
   reviews go back to the planner, who refines the proposals: a propose-review loop. The loop
   ends when further review can no longer materially change those top proposals. (Rust RFCs,
   Google design docs, KEPs with reviewers distinct from authors, PEP 1, Amazon's Type 1 and
   Type 2 decisions.)
4. **Plan: decide.** The reviewed proposals reach the decision maker, usually the lead
   developer. The simulated user reviews first, and the person, when present, reviews on top of
   the simulated user. Their textual feedback and numerical corrections send the proposals back
   to step 2: a propose-review-decide loop. To end the loop, the decision maker approves some
   proposals as change requests for step 5. The decision maker's feedback and corrections
   become in-iteration data. (Rust, PEP 1, HashiCorp RFCs.)
5. **Code, build and test.** The automatic coder writes the change requests on a branch, in
   order. Each change request passes its gates, the checks of its kind, or is abandoned.
   Changes that pass join a merge queue; a change that fails drops out, and the reason is
   logged. When the candidate v+1 and the current v are run side by side on the same items,
   code scores the difference on metrics fixed before the run. (GitHub required checks and
   merge queue; Software Engineering at Google; Google SRE canarying; Spinnaker Kayenta.)
6. **Code review.** A gate before release. The code reviewer, an agent separate from the coder,
   reviews the diff and either accepts the code or sends the code back to the coder with the
   review. Either way the review is written down, and step 1 reads it. (Google code review;
   GitHub's required review, approve or request changes.)
7. **Release and deploy, to developers.** The decision maker, the simulated user first and the
   person on top, releases v+1 or keeps v, with the code review in hand, and with the graded
   runs of the side-by-side comparison when there are any. A release that proves worse is
   reverted. Any runs go on to step 1. (Software Engineering at Google; LLVM; feature toggles;
   DORA on change approval.)

A release goes to developers. A released M.f is expected to be fit for developers' runs.

Runs after a release, by real users, developers or automation, on items inside or outside M's
dataset, may happen at any time, and their records go to step 1.

The person comes in at steps 4 and 7. No author reviews its own artifact. (ITIL's standard
change; DORA on change approval.)

## Retrospective and curation

Two activities sit beside the loop rather than in its sequence. Each is placed where its input
appears.

- **Retrospective** looks at how S itself worked: which findings, proposals, reviews and checks
  helped, and which cost time and gave nothing. S holds one retrospective per loop, after
  monitor, and a postmortem at once after a release that proves worse. The retrospective's
  changes to S are changes like any other, made in S's in-iteration layer first. (Scrum; Google
  SRE.)
- **Curation** is upstream applied to labels. Grades, feedback and priority orders that prove
  useful beyond their layer move up, whenever needed, off the critical path. (LangSmith and
  Langfuse datasets.)

## The run record

Each run record holds:
- the versions of M and S;
- the settings;
- the item;
- the trace: every model call and tool call the run made, each with its start, end, inputs and
  outputs, nested under the call that started it (OpenTelemetry's spans);
- the outcome;
- the grades, and who gave each;
- time, tokens and cost.

(MLflow runs, OpenTelemetry's GenAI agent spans, SLSA provenance, and Anthropic's split between
transcript and outcome.)

## Sources

The surveys in `survey/` of the repository `shared`: `survey-development-flow.md`,
`survey-change-kinds.md`, `survey-improvement-step.md`, `survey-process-terms.md`, and, for the
layers, `survey-layered-templates.md`.

## Metadata

- The mantras and habits were moved from the N2S repository, where the person approved them,
  with "the Director" written as "the person". The mantras' examples stay with the person's
  data, because they hold the person's own words about one project.
- Versioning is generalised from N2S's `prototype2/VERSIONING.md`.
