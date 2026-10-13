# S: from human-driven to AI-driven development

## Context

Projects and their components have been developed by people driving AI assistants by hand. From
now on a development system, S, does the development, and the person labels. A project or a
component that was developed by other means is first prepared, and then synced, so that S
develops it from then on and learns across iterations, projects and many projects. This plan is
the frame for that work, read top-down. The plan aims at the grand vision, knowing the build will
fall short of the vision for a while.

Content moves through four legs: sync from `shared` to a project (1), sync from the project to a
component (2), upstream from the component to the project (3), and upstream from the project to
`shared` (4).

The disciplines throughout:
- Known best practice first. Each detail names the practice it follows, and how closely.
- Examinable increments. Nothing has to be final in one shot.

## 1. The vision

A person says what the person wants, and then only labels. A development system (S) builds,
reviews and improves a project (M). A project holds one or more components, and each component
contains a plan (M.p) and a prototype (M.f). S serves many M's. As S is invoked on an M, S improves M.p and M.f, and S also improves S's own parts.

S iterates over selected improvements, from version v to version v+1. More precisely, S moves
M.p.v and M.f.v to M.p.v+1 and M.f.v+1, and moves S's own parts to their next versions. A
release goes to developers only. A released M.f is expected to be fit for developers' runs, and
not for end users.

The constituent parts of S:
- **The method:** the mantras, the habits, and the way any change is made, checked and
  recorded.
- **The roles**, each defined by its actions and played by a person, an AI or a program: the
  user, the decision maker, the run reviewer, the planner, the proposal reviewer, the coder and
  the code reviewer.
- **The data** the roles act on: use cases, run records, run grades, run reviews, proposals,
  proposal reviews, decisions and code reviews.

S's parts take the form of specs, config, data and programs.

Each of S's parts sits in one of three categories, or layers:
- **Pan-project:** shared by every M. Pan-project parts may include components offered
  commercially.
- **In-project:** S initializes in-project parts when an M starts. In-project parts evolve as
  the M goes. Content that proves general enough is elevated to pan-project.
- **In-iteration:** S initializes in-iteration parts when a component of an M comes under S.
  The in-iteration parts sit beside the component's generations, such as f5, outside each one,
  and serve each major iteration in turn. Content that proves general enough is elevated to
  in-project.

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
   states the gain, the delta to M.p.v, the kind, the design, the tasks, the check, and its
   upstream status: local to this layer, or a candidate for the layer above. The planner
   quantifies each proposal's upsides and downsides, and orders the proposals by them; the order
   is the planner's alone. Proposals too slight to matter are not written. (The upstream status
   follows Debian's DEP-3 `Forwarded:` field and Android's `UPSTREAM:`/`ANDROID:` tags.)
3. **Plan: review.** The proposal reviewers, agents separate from the planner, review the
   proposals at the top of the order, and give textual feedback and numerical corrections. The
   reviews go back to the planner, who refines the proposals: a propose-review loop. The loop
   ends when further review can no longer materially change those top proposals. (Rust RFCs,
   Google design docs, KEPs with reviewers distinct from authors, PEP 1, Amazon's Type 1 and
   Type 2 decisions.)
4. **Plan: decide.** The reviewed proposals reach the decision maker, usually the lead developer.
   An AI playing the user reviews first, and the person, when present, reviews on top. Their textual feedback and numerical corrections send the proposals back to
   step 2: a propose-review-decide loop. To end the loop, the decision maker approves some
   proposals as change requests for step 5, confirming each one's upstream status. The decision maker's feedback and corrections become
   in-iteration data. (Rust, PEP 1, HashiCorp RFCs.)
5. **Code, build and test.** The coder writes the change requests on a branch, in
   order. Each change request passes its gates, the checks of section 2.1, or is abandoned.
   Changes that pass join a merge queue; a change that fails drops out, and the reason is logged.
   When the candidate v+1 and the current v are run side by side on the same items, code scores
   the difference on metrics fixed before the run. (GitHub required checks and merge queue;
   Software Engineering at Google; Google SRE canarying; Spinnaker Kayenta.)
6. **Code review.** A gate before release. The code reviewer, an agent separate from the coder,
   reviews the diff and either accepts the code or sends the code back to the coder with the
   review. Either way the review is written down, and step 1 reads it. (Google code review;
   GitHub's required review, approve or request changes.)
7. **Release and deploy, to developers.** The decision maker, with an AI playing the user first
   and the person on top, releases v+1 or keeps v, with the code review in hand, and with the graded
   runs of the side-by-side comparison when there are any. A release that proves worse is
   reverted. Any runs go on to step 1. (Software Engineering at Google; LLVM; feature toggles;
   DORA on change approval.)

Runs after a release, by real users, developers or automation, on items inside or outside M's
dataset, may happen at any time, and their records go to step 1.

**Runs inside a step.** A step may include runs at two points, and may include none.
- Before release, a simulated developer or the person makes one or more trial runs of the
  candidate v+1. A trial run logs more than a true run does.
- After release, simulated users or real users make one or more trial runs or true runs of v+1.

**Triggering and chaining.** A person can start each step by hand, or an event can start it
automatically, such as the previous step's output arriving. At each hand-off, the role that
finishes writes its output into the layer's `S/data/<type>/`, and the next role takes the output
from there. `step.sh` plays the chain: it hands each step to the step's role, records each
hand-off, and stops where the chain waits for a person. `chain.json` gives the chain, and
`shared` gives the default chain. A project or a component customises how its
steps chain together: which hand-offs pass automatically, which wait for a person, and which
runs the step includes. A layer can close the loop fully, or leave some hand-offs to a person.
(GitHub Actions' `workflow_dispatch` beside event triggers; manual approval gates in CI/CD
pipelines.)

Two activities sit beside the loop rather than in its sequence, each placed where its input
appears:
- **Retrospective** looks at how S itself worked. S holds one retrospective per loop, after
  monitor, and a postmortem at once after a release that proves worse. (Scrum; Google SRE.)
- **Curation** is upstream (section 5) applied to data. The role that produces each piece of data
  sends the piece upward as the piece proves useful beyond its layer, off the critical path
  (section 6).

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

## 3. The layers on disk

```
shared/                       the pan-project layer, a public GitHub repository
  survey/                     the evidence the specs cite
  S/specs/                    mantras, habits, building, versioning, step, data, sync, one per role
  S/config/                   CLAUDE.md, .claude/ (settings.json, hooks/, skills/)
  S/data/<type>/              one folder per data type, with its format and general samples
  S/outbox/<type>/            empty: shared is the top layer
  S/src/                      sync.sh, upstream.sh, step.sh, chain.json,
                              agents/<role>/ (each role's prompt, settings, code)

N2S/                          the project
  shared/                     shared, as a git submodule, pinned per project
  CLAUDE.md, .claude/         the project's config
  S/                          the in-project layer: survey/, specs/, data/, outbox/, src/
  prototype2/                 a component
    CLAUDE.md                 the component's own rules
    spec/                     M.p
    f0/ … f5/                 M.f, one folder per generation
    S/                        the in-iteration layer, built by the component's own sync:
                              specs/, data/, outbox/, src/
```

Each layer's sending agents write into that layer's `S/outbox/<type>/`. The layer above pulls
from it: N2S pulls `prototype2/S/outbox/`, and `shared` pulls `N2S/S/outbox/`.

Each layer holds whole working copies, customised for that layer. (Kustomize's base and
overlays; Copier; git submodules.)

## 4. Sync, legs 1 and 2

`shared/S/specs/sync.md` is the spec. A project pins `shared` as a submodule, copies `sync.sh`,
customises it, and runs it. `sync.sh` copies the documents, then the config, then the data, then
the programs, and reports. A later run merges `shared`'s changes into the project's copies with a
three-way merge, keeping the project's own changes. Leg 2 is a component's own customised
`sync.sh`, which builds the component's S the same way from the project's layer, read from the
project's git history at a recorded commit.

## 5. Upstream, legs 3 and 4

Sources: `~/shared/survey/survey-upstreaming.md`, `survey-curation-roles.md`.

Each role carries its own work upward. A role's agent at the downstream layer sends; the same
role's agent at the upstream layer receives. The roles act continuously, each piece at its own
opportunity: when the role produces the piece, when a duplicate appears, when the upstream layer
changes. No role moves a whole store in one batch. (Tag at birth and a continuous sweep: the
Linux stable process, Debian's patch tracker.)

**The sending agent** holds the downstream layer's context, so the sending agent does the work
that needs context:
- submits whatever could help an agent of any role elsewhere, not only the sending role: a
  piece is judged by its use to a to-agent, and the from-agent submits it. Which pieces a
  to-agent later reads is a separate question;
- tags each change or piece of data at birth, as local or as a candidate for the upstream layer
  (Debian's DEP-3 `Forwarded:`; Android's `UPSTREAM:` tags), and tags it again at the step's
  submit pass, when the whole step shows what the piece was worth;
- tracks what the downstream layer carries, and raises a candidate left unsent too long as a
  finding;
- collects, removes duplicates and clusters near duplicates against what the sending agent has
  already sent, in its outbox: one lesson is one piece, revised in place, and a piece that
  supersedes another retires it (section 6);
- revises the content into the upstream layer's terms (section 7), and sends the piece.

**The receiving agent** lacks the downstream layer's context, so the receiving agent judges each
piece as received, and accepts or drops the piece. The receiving agent does not revise the piece.
At `shared`, the person decides on top. (The upstream maintainer judges a change on its own
merits: the Linux kernel, Debian, InnerSource; Fedora keeps a person as the final decider.)

**Acceptance chains upward.** Once the receiving agent accepts a piece, the receiving agent
becomes the sending agent for that piece toward the next layer up, with its own layer's context.

**Back down.** At the downstream layer's next sync, an accepted change replaces the local copy;
an accepted piece of data comes back beside the local entry it was revised from, and the
downstream layer keeps its own entry, with its context, marked as accepted. A dropped piece stays in the downstream layer, marked local
and visible. (Ubuntu's sync drops a carried change; Android forbids hiding a rejected patch.)

`step.sh` gives each role its first opportunity to send: when the role writes an entry tagged as
a candidate, `step.sh` has the same role's sending agent revise the entry into the layer's
outbox. `upstream.sh`, run at the layer above, gives the receiving agents their opportunity.

Each role's agent performs these acts by calling the APIs and running the programs each act needs.
The coder builds those programs; the role that runs a program answers for the program's results.
(LangSmith, Label Studio, Dependabot: a program performs the act, a named role owns the program.)

## 6. Data and curation

Source: `~/shared/survey/survey-data-curation.md`. The role that produces each data type sends
the type upward, and the same role at the upstream layer receives the type: the run reviewer for
run reviews, the user for use cases and run grades, the planner for proposals, the proposal
reviewer for proposal reviews, the decision maker for decisions, the code reviewer for code
reviews.

The sending agent:
1. **collects** each entry with its author (person, AI or program), its origin (layer and source
   id), a content hash, a status and a version (LangSmith, Langfuse, Argilla, MLflow);
2. **removes exact duplicates** by the hash of a normalised entry;
3. **clusters near duplicates** by direct pairwise comparison, keeping repeated judgements of one
   item as agreement, merging only true copies, and letting a later decision of the person
   retire an earlier one (CROWDLAB; NeMo Curator; SemDeDup);
4. **cleanses** each entry that an automated check flags for a label error, a secret or
   contamination (cleanlab; detect-secrets).

The receiving agent accepts or drops each entry. The upstream layer commits each accepted entry
into the layer's dataset and tags a new version (git commit and tag), and each data folder's
README states the folder's licence.

## 7. Context in upstreamed examples

Source: `~/shared/survey/survey-example-context.md`. The sending agent revises each example into
the smallest form that still shows the example's point, plus the context a stranger needs:
- the sending agent **keeps** the evidence and the verdict word for word: log lines, diff hunks,
  the grade and its reason, numbers with units;
- the sending agent **adds** only what removes an ambiguity: the downstream layer's ids and
  jargon replaced by what they mean, one sentence of environment, the reference stated in words
  (decontextualisation; KCS; contextual retrieval);
- the sending agent **drops** every piece whose removal leaves the verdict unchanged, largest
  first (delta debugging), and summarises long logs with a link to the original.

On leg 3 the sending agent replaces what is specific to the component and keeps the project's
terms. On leg 4 the sending agent also replaces the project's terms, and writes the example in
pattern form: context, problem, solution, consequences. The receiving agent's acceptance is the
test of the revision: an example the receiving agent cannot judge without the downstream context
lacks context.

## 8. The reviewers

- **Code:** a ready-made reviewer (PR-Agent) on our router.
- **Runs and proposals:** built by us, learning the person's standard from examples with
  reasons, and measured by agreement with the person (Cohen's kappa, set against the person's
  own consistency on items re-labelled blind). (`~/shared/survey/survey-ready-made-reviewers.md`,
  `survey-simulated-reviewer.md`.)

## 9. Order of work

1. Leg 1, sync from `shared` to N2S: built and run.
2. Leg 4, upstream from N2S to `shared`: built and run.
3. The chain in `shared` (`step.md`, `step.sh`, `chain.json`), and legs 2 and 3.
4. A trial on the toy project textkit, one project with two components, with no person in the
   loop: legs 1 to 4, later syncs with three-way merges, and three steps on each component. The
   gaps it found are fixed in `shared`. textkit's `main` stays at its starting state; each trial
   keeps its records on its own branch, in textkit and in `shared`.
5. N2S: later sync from `shared`, leg 2 to prototype2, and a step of S on prototype2.

## 10. Open decisions

1. A middle home for content general to some projects but not all, as Kustomize components
   allow.
2. The first source of use cases.
3. The blind re-labelling of 20–30 items.

## Metadata

- Revised on 2026-10-12 with the surveys of upstreaming, data curation and example context, and
  later that day with the model of sending and receiving agents and the survey of curation roles.
- Revised on 2026-10-13: components inside a project, S beside a component's generations, the
  outboxes, runs inside a step, and triggering and chaining.
