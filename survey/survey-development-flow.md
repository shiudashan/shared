# The established flow of one development step

The established flow has the same shape everywhere. A change is proposed in writing. It is
reviewed. One person with authority decides. It is built. It is checked twice: against its spec
(verification) and in use (validation). It is released as a new version with a changelog entry
and a tag. The cycle ends with a retrospective on the process. The author never approves the
author's own work. The kind of change decides how it is checked.

Our draft of section 2.2 has most of these steps. It lacks four: a written proposal per change,
a review of the proposal before the person decides, a split between verification and
validation, and a comparison of v+1 against v run side by side. It also says "rejected" where
established practice says "postponed".

## Proposed replacement for section 2.2

**2.2 Incremental development: one step of S, from v to v+1.**

1. **Use.** The simulated user runs M.f.v on items from M's dataset. Each run leaves a run
   record: the version, the settings, the item, the full transcript, and the outcome.
   *Source:* Anthropic's eval terms (task, trial, transcript, outcome); MLflow runs; OpenTelemetry
   GenAI agent spans. The simulated user standing in for the person is *ours*. Its nearest
   established form is acceptance testing by the customer (XP), done here by a stand-in.
2. **Review the runs.** The automatic reviewer reads the transcripts and writes findings. Each
   finding names the symptom in the run record it rests on.
   *Source:* Scrum's Sprint Review ("inspect the outcome"); Anthropic: "read the transcripts".
3. **Propose.** The automatic planner writes each change as a change proposal: why, a delta to
   M.p, the design, the tasks, the kind of change, and the check that will show it worked.
   *Source:* OpenSpec `propose`; Spec Kit `specify`, `plan`, `tasks`; Kiro's three phases; the
   Rust RFC and the KEP. Kinds and their checks: section 1 below.
4. **Review the proposals.** The automatic reviewer checks each proposal for consistency with
   M.p and with the method, and for a check that can decide it. The reviewer is not the planner.
   *Source:* Spec Kit `analyze` and `checklist`; Google design review; KEP: reviewers "should
   be a distinct set from authors".
5. **Order.** The simulated user orders the reviewed proposals.
   *Source:* Scrum: the Product Owner orders the backlog and "may delegate" the work but
   "remains accountable". Here the person is accountable and the simulated user is the
   delegate.
6. **Decide.** The person reads the proposals, reviews and order, and gives feedback. S returns
   to step 3 with it. When the person has no more feedback, the person approves some proposals.
   The others are postponed: they go back to the backlog and may be proposed again.
   *Source:* Rust RFC final comment period and its three dispositions (merge, close, postpone);
   PEP "Deferred"; Shape Up's betting table; Kiro and Claude Code plan approval before any edit.
   Shape Up's variant drops unchosen pitches entirely ("we let it go"); Scrum returns them to
   the backlog. Either is established.
7. **Build.** The automatic coder builds the approved changes on a branch, task by task. It runs
   each change's check as it goes.
   *Source:* Spec Kit `implement`; OpenSpec `apply`; Claude Code "give Claude a way to verify
   its work".
8. **Verify.** S checks the build against M.p.v+1: each change's own check passes, the
   regression checks still pass, and a reviewer other than the coder reviews the diff.
   *Source:* Spec Kit `converge`; OpenSpec `verify`; Google code review; Claude Code's
   adversarial review in a fresh context; GitHub's rule that the requester cannot approve the
   agent's pull request.
9. **Validate.** The simulated user runs the candidate v+1 and v on the same items, at the same
   time. The automatic reviewer compares the two run records.
   *Source:* the continuous-delivery deployment pipeline (later stages run fuller tests on the
   same build); Google SRE canarying (canary against control, not before against after);
   Anthropic's regression evals.
10. **Release.** The person approves the release. S merges the deltas into M.p, writes the
    changelog entry, and tags M.p.v+1 and M.f.v+1 together. A released version is never
    changed. Rollback is a return to the tag of v.
    *Source:* OpenSpec `archive`; Keep a Changelog; Semantic Versioning; MLflow's "champion"
    alias moved to the new version.
11. **Retrospective.** S improves S's own in-iteration parts from what this step showed.
    *Source:* Scrum's Sprint Retrospective ("plan ways to increase quality and effectiveness").
12. **Elevate.** S moves in-iteration data that proved general to in-project data, with the
    person's approval. *Ours.* No surveyed process has a layer above the project that learns
    from it.

**Who holds which point.** The person holds two points: decide (6) and release (10). Every other
point is automatic. This matches ITIL's "normal change", which needs an authority's approval.
ITIL's "standard change" is pre-approved because it is low-risk and well understood. Once the
measured agreement between the automatic reviewer and the person is good enough, a kind of
change can become a standard change, and point 10 becomes automatic for it. *(Inferred: ITIL
does not speak about simulated reviewers. It gives the shape of the rule.)*

## 1. Kinds of change and how each is checked

**Conventional Commits.** The spec names `fix` (maps to PATCH) and `feat` (maps to MINOR). A
`!` or a `BREAKING CHANGE:` footer maps to MAJOR, whatever the type. It "recommends `build:`,
`chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, and others". These "have no
implicit effect in Semantic Versioning". The Angular guide defines them. `perf`: "A code change
that improves performance". `refactor`: "A code change that neither fixes a bug nor adds a
feature". `build`: "Changes that affect the build system or external dependencies". `docs`:
"Documentation only changes". commitlint adds `revert`.

**Swanson and ISO/IEC 14764.** Swanson (ICSE 1976) named three kinds of maintenance:
corrective, adaptive, perfective. Lientz and Swanson later added preventive. ISO/IEC 14764
keeps the four. Corrective: "to fix a bug or other failure to meet requirements". Adaptive: "to
ensure its continuing usability in a changed or changing environment". Perfective: "to improve
qualities such as user experience, processing efficiency". Preventive: "forward-looking
modification". These sort changes by motive, not by what the diff touches. Authors draw the
lines differently (Mockus and Votta call restructuring perfective).

**ITIL change types.** Standard (pre-approved, low risk, well understood), normal (assessed
and authorised, with assessment "proportional to the risk"), emergency (expedited). ITIL 4
replaces the single Change Advisory Board with a "change authority", which can be a peer
review or automated testing. These sort changes by risk and by who approves.

**Refactoring.** Fowler: "a change made to the internal structure of software to make it
easier to understand and cheaper to modify without changing its observable behavior." The
check is that behaviour does not change: the existing tests pass unchanged. Large rewrites
are done in steps by **branch by abstraction** ("making a large-scale change to a software
system in gradual way") or **parallel change** (expand, migrate, contract).

**Performance.** benchstat compares old and new runs with a median, a 95% confidence interval
and a p-value. "Each benchmark should be run at least 10 times." Fix the run count in advance,
and interleave before and after runs. Brendan Gregg's **active benchmarking**: "you analyze
performance while the benchmark is still running", with a profile, to find the real limiting
factor. A speed change also keeps behaviour, so it carries the refactor check too.

**Alternative paths and instrumentation.** GitHub's Scientist runs the old path (the
"control") and the new one (the "candidate"), always returns the control's result, and
records both results and timings. Fowler's **dark launching** calls new back-end behaviour
"from existing users without the users being able to tell". Google SRE **canarying** is "a
partial and time-limited deployment of a change in a service and its evaluation", compared
against the control at the same time. Feature toggles (Hodgson) split into release,
experiment, ops and permissioning toggles. Added instrumentation that only collects statistics
has no type of its own in any taxonomy surveyed. *(Inferred check: outputs unchanged, and the
new signal appears in the run record.)*

**Data, model and prompt changes.** CD4ML (Thoughtworks) versions three things: "the code
itself, the model, and the data." Its checks are threshold tests against a baseline, checks per
data slice, and shadow, canary or A/B deployment. For prompts and agents, Anthropic separates
**capability evals** ("What can this agent do well?") from **regression evals** ("Does the agent
still handle all the tasks it used to?"), which "should sit near a 100% pass rate". Model
graders "should be closely calibrated with human experts". OpenAI: "run evals on every change"
and "Use human feedback to calibrate automated scoring."

**What we would adopt.** Use the Conventional Commits types as the kind of change: `feat`,
`fix`, `refactor`, `perf`, `docs`, `test`, `build`, plus `!` for breaking. Keep
"instrumentation" as *ours*. Each kind brings its check: a feat brings new acceptance scenarios
in its delta; a fix brings a failing test that reproduces it (Kiro's bugfix spec keeps
"current", "expected" and "unchanged" behaviour); a refactor brings unchanged regression
checks; a perf change brings a before-and-after benchmark and a profile; an instrumentation
change brings unchanged outputs and the new signal; a prompt change brings regression and
capability evals. This replaces the "(Our invention.)" line in section 2.1.

## 2. The step-by-step flow and its review points

**OpenSpec.** Explore (optional), `propose` (writes `proposal.md`, delta specs, `design.md`,
`tasks.md`), review by the person ("you review the plan before any code is written"), `apply`,
`verify` (optional: "Check implementation matches specs"), `archive` (merges the deltas into
the main specs and moves the change to a dated archive folder). It has "no rigid phase gates".

**GitHub Spec Kit.** `constitution`, `specify`, `clarify`, `plan`, `checklist`, `tasks`,
`analyze`, `implement`, `converge`. The plan has "Phase -1 gates" tied to the constitution.
"The LLM cannot proceed without either passing the gates or documenting justified exceptions."
Checklists are reviewer-owned: an agent may help, but "implementation must not silently
self-approve them". `analyze` is read-only and suggests fixes "for you to approve". `converge`
checks the build against the artifacts and appends the remaining tasks.

**Kiro.** Requirements, then design, then tasks. The person reviews each phase: "Confirm when
requirements meet your needs", "Confirm the design is feasible", "Review the task breakdown".
"Quick Spec" runs all three "without approval gates".

**Rust RFC.** A pull request, labelled to a sub-team. When the trade-offs are clear, a
sub-team member moves a final comment period with a disposition: merge, close or postpone.
All sub-team members sign off first. It runs ten days. "A sub-team makes final decisions."
Acceptance does not assign anyone to build it; a tracking issue follows.

**Python PEP.** Draft, then Accepted by the Steering Council or a PEP-Delegate, then Final once
"the reference implementation is complete and incorporated". Other states: Rejected, Deferred,
Withdrawn, Superseded.

**Kubernetes KEP.** provisional, implementable ("The approvers have approved this KEP for
implementation"), implemented, plus deferred, rejected, withdrawn, replaced. Reviewers and
approvers "should be a distinct set from authors". A separate team does the **production
readiness review**, which checks that a feature is "observable, scalable and supportable". It
blocks every stage since 1.21.

**Google.** Design docs move through creation, review, implementation and maintenance. The doc
is updated as implementation finds faults. Code review: approve once the change "definitely
improves the overall code health of the system, even if the CL isn't perfect." The reviewer
approves.

**Scrum.** Sprint Planning, Daily Scrum, Sprint Review ("inspect the outcome of the Sprint and
determine future adaptations"), Sprint Retrospective. The Definition of Done is "a formal
description of the state of the Increment". Work that does not meet it "returns to the Product
Backlog for future consideration."

**XP.** The planning game has release planning and iteration planning, each with exploration,
commitment and steering. Small, frequent releases. Tests are written before code. The customer
"should be on hand at all times".

**Shape Up.** Shaping by senior people, a written pitch, a betting table where "stakeholders
decide what to do in the next cycle", a six-week cycle, a two-week cool-down. A bet is "the
decision to commit a team to a project for one cycle with no interruptions". A project that
runs over gets no extension by default (the "circuit breaker"). Unchosen pitches are dropped:
"There's nothing we need to track or hold on to."

**Continuous delivery and DORA.** "Every change in version control triggers" a commit stage of
fast tests and checks; "every passing commit stage triggers the next step", with fuller tests;
passing builds "can then be deployed on demand" to later stages. "Only build packages once."
DORA measures change lead time, deployment frequency, failed deployment recovery time, change
fail rate and deployment rework rate.

**ML practice.** Runs are tracked as experiments. A model version is registered and linked "to
the MLflow run … that produced it". It is promoted by moving an alias such as "champion".
CD4ML adds quality gates against a baseline and optional manual review stages.

**Who holds each point.** The author writes. Reviewers, distinct from the author, review. One
named authority approves: the Product Owner, the sub-team, the Steering Council, the KEP
approvers, the betting table, the change authority. Release engineering, often automated
("Push on Green"), releases. The team holds the retrospective. Checks, consistency analysis
and code review comments can be automated. The decision to fund a change and the decision to
release are held by people in every process surveyed, except ITIL's pre-approved standard
changes and push-on-green teams.

**What we would adopt.** The order of section 2.2 above. A proposal state per change, from
KEP and PEP: proposed, approved, built, released, or postponed, withdrawn, replaced. The rule
that reviewers and approvers are not the author.

## 3. Artifacts and the run record

**Per change.** The proposal, its delta spec, design and tasks (OpenSpec, Spec Kit, Kiro). The
review comments. The decision with its disposition, who made it and why (RFC, KEP status,
ADR). The check results. The changelog entry. All of these stay in the archive after release
(OpenSpec: "the proposal, design, tasks, and specs stay in the archive").

**Per run.** The established fields, combined:
- From MLflow runs: parameters, metrics, artifacts, tags, start and end times.
- From MLflow model versions: a link to the run that produced each version.
- From MLflow tracing: "the inputs, outputs, and metadata associated with each intermediate
  step", with "latency and token usage at each step". Human feedback is "attached to traces and
  recorded with metadata, including user, timestamp, revisions".
- From OpenTelemetry GenAI conventions: one `invoke_agent` span per agent run, holding
  `execute_tool` spans and model-call spans, tagged with `gen_ai.agent.name` and
  `gen_ai.conversation.id`. Prompt and completion content is not captured by default. These
  conventions are in Development status and have moved to their own repository.
- From SLSA provenance: the build type, the external parameters, the resolved dependencies,
  and the builder, plus an invocation ID and start and finish times.
- From SWE-agent: a trajectory file holding each (thought, action, observation) turn, the
  messages shown to the model, and the exit status and final patch.
- From Anthropic's eval terms: the transcript ("the complete record of a trial, including
  outputs, tool calls, reasoning, intermediate results") and the outcome ("the final state in
  the environment"), kept apart. The outcome is what changed, not what the agent claimed.
- From Claude Code: "Have Claude show evidence rather than asserting success: the test output,
  the command it ran and what it returned."

**What we would adopt.** A run record that holds: the version of M (tags of M.p and M.f) and of
S (commits of `shared` and the project); the settings; the item; the transcript as nested
spans named in the OpenTelemetry GenAI way; the outcome; the grades and who gave them; and
times, tokens and cost per span. That is enough for a reviewer to judge a run without
re-running it.

## 4. Releases

**Cutting a version.** Semantic Versioning: a released version "MUST NOT be modified". Keep a
Changelog: an "Unreleased" section collects changes, and "at release time, you can move the
Unreleased section changes into a new release version section". Google release engineering:
each release carries a label "which guarantees that a package can be uniquely referenced";
builds are hermetic.

**Rollback.** Return to the previous released version. Keep a Changelog marks a pulled version
`[YANKED]` and keeps it listed. MLflow rolls back by moving the alias back. Google release
branches take fixes by cherry-pick from the mainline. DORA counts how often a release needs
"immediate intervention", by rollback or hotfix.

**Release trains or per-change releases.** Rust: "every six weeks, a release 'leaves the
station'", through nightly, beta and stable; unfinished work rides behind feature flags. Chrome
ships a milestone to stable on a fixed schedule after a branch point and stabilisation.
Continuous delivery releases each change that passes the pipeline; some Google teams "deploy
every build that passes all tests".

**What we would adopt.** One release per step: the step's approved changes ship together as
v+1. That is a short train whose length is one step. A change that fails verification does not
hold the train: it goes back to the backlog, as in Scrum's Definition of Done. Rollback is the
tag of v.

## 5. Agentic development flows (2025–2026)

**Claude Code.** Plan mode: "Claude reads files and proposes a plan but makes no edits until you
approve." The recommended flow is explore, plan, implement, commit. Give the agent "a check it
can run". The check can gate the stop through a Stop hook or a `/goal` condition. For review, a
fresh-context subagent "sees only the diff and the criteria you give it", so "the agent doing
the work isn't the one grading it." A reviewer told to find gaps "will usually report some, even
when the work is sound", so flag "only gaps that affect correctness or the stated
requirements".

**OpenAI Codex.** Each cloud task runs in its own sandboxed workspace. The person inspects the
changed files and results, then commits or opens a pull request. Codex code review runs on
request (`@codex review`) or on every pull request, reports only P0 and P1 issues, and reads
review guidelines from `AGENTS.md`.

**Devin.** Interactive planning: Devin searches the code, then proposes a plan with code
references for the person to check before it codes. It opens pull requests for review. I could
not confirm from the English docs whether it waits for approval or proceeds on a timeout.

**OpenHands.** The resolver acts on an issue labelled `fix-me`. It opens a draft pull request if
it succeeds, or pushes a branch if not, and comments on the issue. (From the package README of
older versions.)

**SWE-agent.** Saves a trajectory file per task, and ships a trajectory viewer.

**Factory.** Specification mode: the agent researches and "proposes a concrete implementation
plan" without editing. It asks for sign-off. The person approves, refines, or raises the
autonomy level for the implementation. Specs can be saved as Markdown.

**Kiro and Spec Kit.** Covered in section 2: per-phase approval in Kiro; reviewer-owned
checklists and "must not silently self-approve" in Spec Kit.

**GitHub Copilot coding agent.** Only users with write access can start it. It pushes only to a
`copilot/` branch. Actions workflows "don't run on a pull request until a user with write
access approves them". The person who asked for the change cannot approve the pull request.
Commits name that person as co-author. Session logs show the work.

**The common pattern.** The agent plans; a person approves the plan before edits. The agent
works in isolation (a branch, a worktree, a sandbox). The agent runs checks and shows the
evidence. A second reviewer, human or model, reviews the diff. The result arrives as a pull
request, and a person other than the requester merges it. The session log or trajectory is the
record.

**What we would adopt.** Plan approval before any edit (step 6). Isolation per step on a branch.
A reviewer in a fresh context for the diff (step 8). The rule that the person who asked cannot
be the only approver does not bind us, since the person asks nothing in our flow: the planner
proposes. The rule we keep from it is that the coder cannot approve its own work.

## Sources

- Conventional Commits 1.0.0: https://www.conventionalcommits.org/en/v1.0.0/
- Angular commit types: https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md
- commitlint config-conventional: https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional
- Software maintenance and ISO/IEC 14764 (Wikipedia): https://en.wikipedia.org/wiki/Software_maintenance
- Swanson, "The dimensions of maintenance", ICSE 1976, doi:10.1145/359511.359522 (via
  https://dzone.com/articles/lientz-and-swanson-software)
- ITIL 4 change enablement (secondary): https://itsm.tools/change-enablement/ ;
  https://faddom.com/itil-change-management-types-standard-vs-normal-vs-emergency/
- Fowler, refactoring: https://martinfowler.com/bliki/DefinitionOfRefactoring.html ; branch by
  abstraction: https://martinfowler.com/bliki/BranchByAbstraction.html ; parallel change:
  https://martinfowler.com/bliki/ParallelChange.html ; dark launching:
  https://martinfowler.com/bliki/DarkLaunching.html
- Hodgson, feature toggles: https://martinfowler.com/articles/feature-toggles.html
- benchstat: https://pkg.go.dev/golang.org/x/perf/cmd/benchstat
- Gregg, active benchmarking: https://www.brendangregg.com/activebenchmarking.html
- GitHub Scientist: https://github.com/github/scientist
- Google SRE, canarying: https://sre.google/workbook/canarying-releases/ ; release engineering:
  https://sre.google/sre-book/release-engineering/
- CD4ML: https://martinfowler.com/articles/cd4ml.html
- Anthropic, evals for agents: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents ;
  building effective agents: https://www.anthropic.com/engineering/building-effective-agents
- OpenAI, evaluation best practices: https://developers.openai.com/api/docs/guides/evaluation-best-practices
- OpenSpec: https://github.com/Fission-AI/OpenSpec ; concepts:
  https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md
- Spec Kit: https://github.com/github/spec-kit/blob/main/spec-driven.md ; commands:
  https://github.github.io/spec-kit/reference/agentic-sdd.html
- Kiro: https://kiro.dev/docs/specs/ ; https://kiro.dev/docs/specs/feature-specs/requirements-first/
- Rust RFCs: https://github.com/rust-lang/rfcs/blob/master/README.md
- PEP 1: https://peps.python.org/pep-0001/
- KEP process: https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/0000-kep-process/README.md ;
  production readiness: https://github.com/kubernetes/community/blob/master/sig-architecture/production-readiness.md
- Google code review: https://google.github.io/eng-practices/review/reviewer/standard.html ;
  design docs: https://www.industrialempathy.com/posts/design-docs-at-google/
- Scrum Guide 2020: https://scrumguides.org/scrum-guide.html
- XP practices: https://en.wikipedia.org/wiki/Extreme_programming_practices
- Shape Up: https://basecamp.com/shapeup/0.3-chapter-01 ; https://basecamp.com/shapeup/2.1-chapter-07 ;
  https://basecamp.com/shapeup/2.2-chapter-08
- Continuous delivery patterns: https://continuousdelivery.com/implementing/patterns/
- DORA metrics: https://dora.dev/guides/dora-metrics-four-keys/
- MLflow tracking: https://mlflow.org/docs/latest/ml/tracking/ ; model registry:
  https://mlflow.org/docs/latest/ml/model-registry/ ; tracing:
  https://mlflow.org/docs/latest/genai/tracing/
- OpenTelemetry GenAI conventions: https://github.com/open-telemetry/semantic-conventions-genai ;
  status and span names (secondary):
  https://greptime.com/blogs/2026-05-09-opentelemetry-genai-semantic-conventions ;
  https://docs.honeycomb.io/send-data/agents
- SLSA provenance: https://slsa.dev/spec/v1.0/provenance
- Keep a Changelog: https://keepachangelog.com/en/1.1.0/
- Rust release train: https://doc.rust-lang.org/book/appendix-07-nightly-rust.html
- Chromium release cycle: https://chromium.googlesource.com/chromium/src/+/main/docs/process/release_cycle.md
- Claude Code best practices: https://code.claude.com/docs/en/best-practices ; common workflows:
  https://code.claude.com/docs/en/common-workflows
- Codex cloud: https://learn.chatgpt.com/docs/cloud ; code review:
  https://developers.openai.com/codex/integrations/github
- Devin interactive planning: https://docs.devin.ai/work-with-devin/interactive-planning
- OpenHands resolver (README): https://pypi.org/project/openhands-resolver/0.3.1
- SWE-agent trajectories: https://swe-agent.com/latest/usage/trajectories/
- Factory specification mode: https://docs.factory.com/cli/user-guides/specification-mode
- GitHub Copilot coding agent: https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent ;
  https://docs.github.com/en/copilot/concepts/agents/coding-agent/risks-and-mitigations

## Metadata

- Written 2026-10-10 for step 1 of the plan's order of work (section 8), to replace the draft
  of section 2.2. The earlier survey `survey-process-terms.md` covered the words; this one
  covers the flow.
- Not verified at a primary source: Swanson's 1976 text (secondary sources); ITIL 4 wording
  (vendor and government copies); the OpenTelemetry GenAI span names (the official page moved,
  names taken from Greptime and Honeycomb); Devin's approval behaviour; OpenHands' current
  resolver behaviour (older README only).
- Marked as inferred in the body: the per-kind check for instrumentation, and the use of ITIL's
  standard change for automating the release point.
