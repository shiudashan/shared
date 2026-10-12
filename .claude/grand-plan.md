# f5: from human-driven to AI-driven development

## Context

f4 was the last generation of f that the person, the Director, drove. From f5 on, an AI-driven
development system does the development, and the person labels. Since the turn to f5, the work
has gone out in many directions with no frame above them. This plan is that frame, read
top-down. The plan aims at the grand vision, knowing the build will fall short of the vision for
a while.

The disciplines throughout:
- Known best practice first. Each detail names the practice it follows, and how closely.
- Examinable increments. Nothing has to be final in one shot.

## 1. The vision

A person says what the person wants, and then only labels. A development system (S) builds,
reviews and improves a project (M), which contains a plan (M.p) and a prototype (M.f). S serves
many M's. As S is invoked on an M, S improves M.p and M.f, and S also improves S's own parts.

S iterates over selected improvements, from version v to version v+1. More precisely, S moves
M.p.v and M.f.v to M.p.v+1 and M.f.v+1, and moves S's own parts to their next versions. A
release goes to developers only. A released M.f is expected to be fit for developers' runs, and
not for end users.

The constituent parts of S:
- **The method:** the mantras, the habits, and the way any change is made, checked and
  recorded.
- **The simulated users:** user simulators, which drive M.f on items from M's dataset and grade
  each run.
- **The automatic reviewers:** review on the person's behalf. The run reviewer judges runs, the
  proposal reviewer reviews proposals, and the code reviewer reviews diffs.
- **The automatic planner:** proposes changes to M.p and M.f.
- **The automatic coder:** builds and checks the selected changes.
- **The person's data:** labels, feedback and reasons, from which the simulated users and the
  automatic reviewers learn.

S's parts may take the form of workflows, prompts or code.

Each of S's parts sits in one of three categories, or layers:
- **Pan-project:** shared by every M. Pan-project parts may include components offered
  commercially.
- **In-project:** S initializes in-project parts when an M starts. In-project parts evolve as
  the M goes. Content that proves general enough is elevated to pan-project.
- **In-iteration:** S initializes in-iteration parts when a major iteration of an M starts. A
  major iteration is a generation, such as f5. In-iteration parts survive only that iteration.
  Content that proves general enough is elevated to in-project.

## 2. Spec-driven development and incremental development

Sources: `~/shared/survey/survey-development-flow.md`, `survey-change-kinds.md`,
`survey-improvement-step.md`, `survey-process-terms.md`.

**2.1 Spec-driven development.** M.p is the spec of M.f.
- Every change to M.f's behaviour is made in M.p first, then in M.f. M.p is reviewed before M.f
  is built from it.
- A change to M.p is written as a delta: what the change adds, modifies or removes. The delta
  merges into M.p when the change is released. (OpenSpec, Spec Kit, Kiro.)
- Each change carries a kind: the Conventional Commits types `feat`, `fix`, `refactor`, `perf`,
  `docs`, `test`, `build`, and `!` for a breaking change, plus instrumentation, an adjustment to
  logging and measurement. Instrumentation is a kind of its own in gitmoji, and OpenTelemetry
  treats emitted signals as a public interface. The short name `instr` is ours.
- An alternative path built beside the existing one, for comparison or for a gradual transition,
  is a technique inside another kind (GitHub's Scientist, branch by abstraction, strangler fig,
  parallel change, canarying).
- Each kind brings its own check. Every number in a check comes from a source or is written in
  the proposal before the run.
  - `fix`: at least one test fails on v and passes on v+1, and every test that passed on v still
    passes (SWE-bench's FAIL_TO_PASS and PASS_TO_PASS).
  - `refactor`: every test that passed still passes, and no existing test is edited. Where tests
    are missing, characterization tests are added first.
  - `perf`: the refactor check, plus at least 10 interleaved runs before and after, with the
    count fixed in advance. The gain counts only if a Mann-Whitney U test gives p < 0.05 and the
    change lies outside the noise band (±2% by default). A profile names the limiting factor.
    (benchstat, criterion, Google Benchmark.)
  - `instr`: behaviour is unchanged, as for a refactor. Each signal the proposal declares appears
    in the run record. Renaming or removing a signal someone reads makes the change breaking.
    (OpenTelemetry.)
  - A prompt change: a case counts as passing on v only if the case passed in all k trials, with
    k set in the proposal, and every such case passes on v+1. Versions are compared by paired
    differences on the same items. (Anthropic's eval guidance; the exact pass rule is ours.)
  - A change using an alternative path adds three checks to its kind's own: with the switch off,
    nothing changes; both paths run on the same items, with success and failure conditions
    written before the run; and the removal of the losing path is planned, with a date.

**2.2 Incremental development: one step of S, from v to v+1.**

A step follows the DevOps loop (plan, code, build, test, release, deploy, operate, monitor),
entered at monitor, because S's proposals come from what the runs show.

Runs come from several drivers: CI/CD tests, developers running M.f on purpose, and real users.
Tests decide right or wrong, and so yield scores automatically. Humans and simulated humans, in
the sense of τ-bench and Anthropic's agent-eval guide, give continuous grades, sometimes without
running the program at all. Runs before or after a release are not guaranteed: the loop works
with whatever runs exist, and with none.

1. **Monitor: review.** The run reviewer reads the run records, if there are any, and the code
   reviews of step 6 in any case. The run reviewer writes findings, the areas to improve. Each
   finding names the symptom it rests on, in the run records or the code reviews, and, where one
   exists, the reference the symptom is judged against. Each finding is graded by severity and
   enters the backlog.
2. **Plan: propose.** From the findings, the planner writes change proposals. Each proposal
   states the gain, the delta to M.p.v, the kind, the design, the tasks and the check. The planner
   quantifies each proposal's upsides and downsides, and orders the proposals by them; the order
   is the planner's alone. Proposals too slight to matter are not written.
3. **Plan: review.** The proposal reviewers, agents separate from the planner, review the
   proposals at the top of the order, and give textual feedback and numerical corrections. The
   reviews go back to the planner, who refines the proposals: a propose-review loop. The loop
   ends when further review can no longer materially change those top proposals. (Rust RFCs,
   Google design docs, KEPs with reviewers distinct from authors, PEP 1, Amazon's Type 1 and
   Type 2 decisions.)
4. **Plan: decide.** The reviewed proposals reach the decision maker, usually the lead developer.
   The simulated user reviews first, and the person, when present, reviews on top of the
   simulated user. Their textual feedback and numerical corrections send the proposals back to
   step 2: a propose-review-decide loop. To end the loop, the decision maker approves some
   proposals as change requests for step 5. The decision maker's feedback and corrections become
   in-iteration data. (Rust, PEP 1, HashiCorp RFCs.)
5. **Code, build and test.** The automatic coder writes the change requests on a branch, in
   order. Each change request passes its gates, the checks of section 2.1, or is abandoned.
   Changes that pass join a merge queue; a change that fails drops out, and the reason is logged.
   When the candidate v+1 and the current v are run side by side on the same items, code scores
   the difference on metrics fixed before the run. (GitHub required checks and merge queue;
   Software Engineering at Google; Google SRE canarying; Spinnaker Kayenta.)
6. **Code review.** A gate before release. The code reviewer, an agent separate from the coder,
   reviews the diff and either accepts the code or sends the code back to the coder with the
   review. Either way the review is written down, and step 1 reads it. (Google code review;
   GitHub's required review, approve or request changes.)
7. **Release and deploy, to developers.** The decision maker, the simulated user first and the
   person on top, releases v+1 or keeps v, with the code review in hand, and with the graded
   runs of the side-by-side comparison when there are any. A release that proves worse is
   reverted. Any runs go on to step 1. (Software Engineering at Google; LLVM; feature toggles;
   DORA on change approval.)

Runs after a release, by real users, developers or automation, on items inside or outside M's
dataset, may happen at any time, and their records go to step 1.

Two activities sit beside the loop rather than in its sequence, each placed where its input
appears:
- **Retrospective** looks at how S itself worked. S holds one retrospective per loop, after
  monitor, and a postmortem at once after a release that proves worse. (Scrum; Google SRE.)
- **Curation** is upstream (section 5) applied to labels: grades, feedback and priority orders
  that prove useful beyond their layer move up, whenever needed, off the critical path.
  (LangSmith and Langfuse datasets.)

The person comes in at steps 4 and 7. No author reviews its own artifact. (ITIL's standard
change; DORA on change approval.)

**2.3 The run record.** Each run record holds:
- the versions of M and S;
- the settings;
- the item;
- the trace: every model call and tool call the run made, each with its start, end, inputs and
  outputs, nested under the call that started it (OpenTelemetry's spans);
- the outcome;
- the grades, and who gave each;
- time, tokens and cost.

The sources are MLflow runs, OpenTelemetry's GenAI agent spans, SLSA provenance, and Anthropic's
split between transcript and outcome.

## 3. The layers: one set of artifacts, customised downward, generalised upward

Every artifact of S, documentation, prompts and source code alike, exists in each layer as a
whole working copy, customised for that layer. Section 5 moves content between the layers.

```
~/shared/                      github.com/shiudashan/shared              pan-project
  survey/                      the surveys the method cites
  S/                           S's artifacts: docs, prompts, code, workflows, feedback

N2S/                           the repository that holds the project
  director-data/               the person's data
  prototype2/                  the project M                              in-project
    shared/                    shared, as a git submodule
    S/                         S's artifacts, customised for M, with the base commit of shared
    f0/ … f4/                  past generations, kept as records
    f5/                        the current generation                     in-iteration
      S/                       S's artifacts, customised for f5, with the base commit of M's S/
      spec, code, VERSION, CHANGELOG
```

The in-project and in-iteration layers stay inside N2S until content is ready to upstream to
`shared`. The file names under each `S/` are the same in every layer (section 4), so the three
copies of one artifact can be compared line by line. Claude Code reads the `CLAUDE.md` of the
layer it works in, which holds that layer's whole customised rules.

## 4. The set of artifacts

The names are ours.

| Artifact | Content |
|---|---|
| `method.md` | How a change is made, checked and recorded: mantras, habits, building rules, versioning, section 2 |
| `simulated-user.md` | How the simulated users draw items, drive M.f, grade runs, and defer to the person |
| `reviewers.md` | How the run, proposal and code reviewers work, and how each review is grounded |
| `planner.md`, `coder.md` | How the planner and the coder work |
| `CLAUDE.md` | The working rules for Claude Code |
| `prompts/` | The prompts of S's agents |
| `src/` | The code of S's agents and workflows |
| `feedback/<id>.json` | Reference entries: question or monitor (optional), symptom, feedback with its reason, status |
| `items/<id>.json` | Labelled items: a seed, its proper answer, its difficulty, its source (project and iteration only) |
| `workflows/sync`, `workflows/upstream` | The two workflows of section 5, themselves customised layer by layer |

## 5. The two workflows

The same practice as git submodules: each layer pins the layer above, pulls its updates, and
pushes its own changes back up.

- **Sync** works from pan-project down: `shared` into the project, then the project into the
  generation. Each layer takes the layer above and customises it.
- **Upstream** works from the generation up: the generation into the project, then the project
  into `shared`, carrying the edits that serve the layer above.

Sync runs when a project or a generation starts. After that, upstream runs periodically,
followed at once by sync.

## 6. The reviewers

- **Code:** PR-Agent, on our router.
- **Runs and proposals:** built by us, growing from f5's feedback mode, learning the person's
  standard from examples with reasons, and measured by agreement with the person (Cohen's kappa,
  set against the person's own consistency on 20–30 items re-labelled blind).
  (`~/shared/survey/survey-ready-made-reviewers.md`, `survey-simulated-reviewer.md`.)

## 7. Order of work

1. Settle the open decisions.
2. Set up the measurement of agreement with the person.
3. Give `shared` its `S/` artifacts and its two workflows.
4. Sync `prototype2` from `shared`, and f5 from `prototype2`, inside N2S.
5. Run steps of S, with the person at steps 4 and 7.

## 8. Open decisions

1. The step of section 2.2.
2. Git submodules, or git subtree, for pinning each layer to the layer above.
3. The first source of items.
4. PR-Agent for code review.
5. A time for the blind re-labelling of 20–30 items.

## Metadata

- Once approved, this plan replaces `prototype2/f5/PLAN.md`.
