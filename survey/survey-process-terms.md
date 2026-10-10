# Our process words against established terms

Most of our words have an established term that fits closely. Adopt it in those cases. Keep our
own word in three places: "generation", "builders read the previous generation", and
"metadata block". No established term covers what those mean here.

"Fit" means: **exact** (same meaning), **close** (same idea, a small difference named in the
line), or **none**.

## The mapping

### Specifying and reviewing

- **spec first** → **spec-driven development (SDD)**. Exact. This is the name used by GitHub
  Spec Kit, OpenSpec and Kiro. Adopt it for the method. "Specs first" can stay as the rule's
  short name.
- **system spec, component specs, interfaces** → **system requirements specification**,
  **software requirements specification** and **interface specification** (ISO/IEC/IEEE 29148).
  Close. In systems engineering, the interface document is called an **interface control
  document (ICD)**. Keep our folder names. Use the established names when describing them.
- **spec patch** → **delta spec** (OpenSpec). Close. OpenSpec groups a change to a spec under
  `ADDED`, `MODIFIED` and `REMOVED Requirements`. Our patches give the section, the old text
  and the new text in full. Adopt "delta spec".
- **improvement plan** (spec change, then code change, then check) → **change proposal**.
  Close. OpenSpec calls it a "change": `proposal.md`, then delta specs, then `design.md` and
  `tasks.md`. Rust RFCs and KEPs are heavier forms of the same thing. Adopt "change proposal".
- **spec review** → **spec review** or **design review**. Exact. Spec Kit runs it as
  `/speckit.analyze` and `/speckit.checklist`, before implementation. Keep.
- **code review** → **code review**. Exact. Keep.
- **DECISIONS.md** (one line per choice the spec left open) → **decision log** of
  **architecture decision records (ADRs)**. Close. An ADR (Nygard) is a short file with
  Context, Decision, Status and Consequences. MADR names the file `docs/decisions/NNNN-title.md`.
  Ours is lighter: one line per decision. Keep the file. Call it a "decision log".
- **read a spec at the strength its words are written** → **requirement keywords** (RFC 2119
  and RFC 8174): MUST, SHOULD, MAY. Close. Our "usually is not always, can is not must" is the
  SHOULD/MUST/MAY split. RFC 8174 adds that only the upper-case words carry that meaning.
- **eval** → **eval** (evaluation). Exact. A set of cases with graders, run against an agent.
  OpenAI Evals uses the same word. Keep.
- **check** (machine-decidable pass or fail) → **check**, as opposed to **test** (Bolton and
  Bach). Exact. "Checking is the mechanistic process of verifying propositions about the
  product." Keep.
- **runtime check** (live, against the router) → **integration test**, or **smoke test** when it
  covers only the main paths (ISTQB). Close. Keep "runtime check" as the name of our script.
- **environment check at start** → **preflight check**. Close. Keep the habit. Use
  "preflight check" when naming it.
- **behaviour kept or deliberately dropped across generations** (habit 17) → **regression
  testing** and **feature parity**. Close. Adopt "regression test" for the check, "parity" for
  the review.
- **reference feedback** (approved entries the simulated user draws on, most similar first) →
  **few-shot examples** selected by similarity, drawn from **labelled examples**. Close. Adopt
  "labelled examples" for the dataset entries.
- **approval queue** → **review queue**, the usual form of a **human-in-the-loop** approval.
  Close. Keep "approval queue". It is plain and widely used.

### Iterating

- **generation (fn)** → no single term. **Major version** fits the number only: SemVer's major
  version signals a breaking change, not a rebuild. Brooks' "plan to throw one away" (the
  **pilot system**) and Fowler's **sacrificial architecture** fit the practice, not the unit.
  Fit: none. Keep "generation". Say that n is the major version number.
- **rewind and re-invent** → **rewrite**, as opposed to **refactor**. Close. A refactor
  changes structure in small steps and keeps behaviour. A rewrite builds again. Ours is a
  rewrite from the spec. Adopt "rewrite from the spec".
- **builders read the previous generation as hindsight** → none. **Clean-room** design is the
  opposite: it forbids reading the old code. "Reference implementation" says the old code is
  authoritative, which it is not. "Prior art" (Rust RFC template) is the nearest, and loose.
  Keep our sentence.
- **lessons file** (`lesson_acted_on_and_learned.md`) → **retrospective**, holding **lessons
  learned**. Close. The Scrum Guide's Sprint Retrospective plans "ways to increase quality and
  effectiveness". PMBOK keeps lessons in a **lessons learned register**. A **postmortem** is
  for an incident, so it does not fit. Our "acted on" half is closer to release notes. Adopt
  "retrospective".
- **circle-back file** → **backlog**. Close. Items set aside on purpose, each with what was
  given up and when to return. Nearby terms: **icebox** (Pivotal Tracker, for ideas not
  scheduled soon), **parking lot**, and **deliberate, prudent technical debt** (Fowler) for
  the entries that are trade-offs. Adopt "backlog". Mark trade-off entries as "debt".
- **PLAN.md** → **iteration plan**. Close. Spec Kit's `plan.md` is a per-feature technical plan,
  a narrower thing. Keep the file name.
- **drive** (the Director uses a generation on a real seed) → **user acceptance testing (UAT)**.
  Close. ISTQB: acceptance testing decides whether the user accepts the system. Ours is
  exploratory, without fixed acceptance criteria. That is an **exploratory test session** (Bach,
  session-based test management). Adopt "acceptance test". Call the notes "acceptance test
  notes".
- **freeze** → **code freeze** and **final release** of a line. Exact. Keep.

### Recording versions and results

- **version n.k** → **MAJOR.MINOR** in the shape of Semantic Versioning. Close. Ours has no
  PATCH. Our k counts single changes, not compatibility. Keep n.k. Name its parts "major"
  (generation) and "minor" (change).
- **tag `fn.<k>`** → **git tag** per release. Close. For one package in a monorepo, the
  established forms are `<component>-v<version>` (release-please) and `<package>@<version>`
  (Changesets). Adopt one of them, for example `f-v5.2`.
- **one commit per version, holding spec, code and tests** → **atomic commit**. Exact.
- **CHANGELOG.md, changelog entry** → **changelog** and its **entries** (Keep a Changelog).
  Exact. Two differences: Keep a Changelog puts the latest version first, and ours puts it
  last. It also groups by type of change (Added, Changed, Deprecated, Removed, Fixed,
  Security), and ours groups by scope.
- **in-project vs cross-project change** → **scope**, as Conventional Commits uses it
  (`fix(parser):`), and **per-package versioning** in a monorepo (Changesets, release-please).
  Close. The established way is one version and one changelog per package. Our two scopes
  share one changelog. Adopt "scope".
- **pinning, lockfile, patches on vendored code** → **pinning**, **lockfile**, **vendoring**
  with a **patch series**. Exact. Keep.
- **keep every version rebuildable** (habit 19) → **reproducible build**. Close. The
  established definition is stronger: any party can recreate bit-by-bit identical artifacts.
  Ours is rebuildability from a tag. Use "rebuildable", and keep "reproducible" for the strict
  sense.
- **run, run folder** → **run** and **run directory** (MLflow; experiment trackers). Exact.
  Keep.
- **run record** (`run.json`: version and settings) → **run metadata**: **parameters**,
  **tags** and the **source version** (MLflow). Close. SLSA calls the same facts for a build
  **provenance**: "where, when and how something was produced". Keep "run record". Store the
  settings under "params" and the version under a "source version" field.
- **profile** → **profile**. Exact. Keep.
- **known problems** → **known issues**. Exact. This is the release-notes heading used by most
  vendors. **Errata** is the term for corrections to a published document. Adopt "known
  issues".
- **setup report** (gap between the spec and the observed machine) → **as-built record**.
  Close. Engineering keeps as-built documents beside the design. Keep "setup report". It is
  plain English.
- **metadata block** (notes about a document, kept after its body) → **metadata**. Close.
  **Front matter** is structured and sits at the top. **Revision history** and KEP's
  **Implementation History** cover only part of it. Keep "Metadata".
- **READY.md** → **release notes**. Close. It says what changed, how to run it, and the
  measured result. Its "How to drive" part is a short **runbook**. Adopt "release notes".
- **BUILD-NOTES.md** → **developer guide**, or **handover notes**. Close. Keep.

## 1. Spec-driven development

Three tools now share one shape. A **spec** states the behaviour. A **plan** or **design**
states the technical approach. **Tasks** break it into steps. Code follows.

- **GitHub Spec Kit.** Commands: `constitution` (project principles), `specify` (requirements
  and user stories), `clarify`, `plan`, `checklist`, `tasks`, `analyze` (consistency before
  implementation), `implement`, and `converge` (checks the build against the artifacts and
  adds the remaining work). The constitution holds "the guiding principles that every later
  phase is evaluated against". Our `CLAUDE.md`, mantras and habits play that role.
- **OpenSpec.** `openspec/specs/` holds "the current agreed-upon behavior". A **change** is a
  folder with `proposal.md`, delta specs, `design.md` and `tasks.md`. **Archive** merges the
  deltas into the main specs and moves the change to `changes/archive/`, with a date prefix.
  Requirements use SHALL. Scenarios use WHEN and THEN.
- **Kiro.** Each spec has `requirements.md` (user stories and acceptance criteria in **EARS**
  notation, for example "WHEN … THE SYSTEM SHALL …"), `design.md` and `tasks.md`. A bug spec
  uses `bugfix.md`, with current, expected and unchanged behaviour.
- **Requirement keywords.** RFC 2119 defines MUST, SHOULD and MAY. RFC 8174 says they carry that
  meaning only in capitals.
- **Requirements standards.** ISO/IEC/IEEE 29148 names the requirements documents. Boehm's
  pair is the usual summary of the other split. **Verification:** "Are we building the product
  right?" **Validation:** "Are we building the right product?" Our checks and evals verify. The
  drive and the simulated user's feedback validate.
- **Proposal processes.** A Rust RFC has Summary, Motivation, Guide-level and Reference-level
  explanation, Drawbacks, Rationale and alternatives, Prior art, **Unresolved questions** and
  **Future possibilities**. Unresolved questions name what is to be settled during
  implementation. That is our "where the spec is silent, decide". A KEP has Goals and
  **Non-Goals**, a Test Plan, Graduation Criteria and an **Implementation History**. Python
  PEPs follow PEP 1.
- **Decision records.** Nygard's ADR has Title, Context, Decision, Status and Consequences. A
  reversed decision is kept and marked **superseded**. MADR adds Considered Options and
  Decision Drivers.

Where the sources agree: the spec states the current behaviour, in the present tense. A change
is written as a proposal with its deltas, and is merged into the spec when done. History and
status are kept apart from the spec's body: OpenSpec's archive, the KEP's Implementation
History, the ADR's Status. That matches our rules "specifications describe the finished
system" and "keep content and metadata apart".

## 2. Incremental development

- **Increment and iteration.** The Scrum Guide: "An Increment is a concrete stepping stone
  toward the Product Goal." Each Sprint ends with a **Sprint Review** (inspect the outcome) and
  a **Sprint Retrospective** (improve how the team works).
- **Spike.** From XP: a short, throwaway experiment that answers one technical question.
- **Prototype.** A **throwaway prototype** is discarded. An **evolutionary prototype** is grown
  into the product. Our generations are neither exactly: each is discarded as code and kept as
  hindsight.
- **Throwing one away.** Brooks, ch. 11: "Plan to throw one away; you will, anyhow." Fowler's
  "sacrificial architecture" accepts that code will be replaced in a few years. Spolsky argues
  against rewriting working code. A rewrite from a maintained spec answers his main objection,
  because the knowledge lives in the spec.
- **Backlog and its relatives.** The Scrum Guide: the Product Backlog is "an emergent, ordered
  list of what is needed to improve the product". Pivotal Tracker's **Icebox** holds stories
  not yet prioritised. Fowler sorts **technical debt** by deliberate or inadvertent, prudent or
  reckless.
- **Lessons.** A retrospective looks at how the team worked. A **postmortem** (Google SRE) is
  "a written record of an incident, its impact, the actions taken to mitigate or resolve it",
  and it is **blameless**. PMBOK keeps a lessons learned register during the project.

Where the sources agree: work is cut into short cycles. Each cycle ends with a review of the
product and a retrospective on the process. Work that is set aside goes to one ordered list.

## 3. Recording versions, findings and results

- **Semantic Versioning.** MAJOR.MINOR.PATCH. "Major version zero (0.y.z) is for initial
  development." "Once a versioned package has been released, the contents of that version MUST
  NOT be modified."
- **CalVer.** Versions from dates, for example `YY.MM`. It suits projects without a stable API.
- **Keep a Changelog.** File `CHANGELOG.md`. "There should be an entry for every single
  version." "The latest version comes first." Types: Added, Changed, Deprecated, Removed,
  Fixed, Security. An **Unreleased** section at the top collects coming changes.
- **Conventional Commits.** `<type>[optional scope]: <description>`. `fix` maps to PATCH,
  `feat` to MINOR, `BREAKING CHANGE` to MAJOR.
- **Monorepos.** A **changeset** (Changesets) is a small Markdown file that declares which
  packages a change touches and the bump for each. release-please keeps a version per package in
  `.release-please-manifest.json` and tags each one `<component>-v<version>`.
- **Reproducible builds and provenance.** A build is reproducible when, from the same source,
  environment and instructions, "any party can recreate bit-by-bit identical copies". SLSA
  provenance records the build type, the external parameters, the resolved dependencies and
  the builder.
- **Experiment tracking.** MLflow: an **experiment** groups **runs**. A run records
  **parameters**, **metrics**, **artifacts**, **tags** and start and end times.
- **Known issues, errata, runbooks.** Release notes carry a "Known Issues" section. Errata
  correct a published document. A runbook is the step-by-step way to operate a system.

Where the sources agree: each release has one version, one tag, and one changelog entry. A
released version is never changed. Each run or build records the version and the parameters
that produced it. In a monorepo, scope is per package, and each package has its own version.

## Sources

- GitHub Spec Kit: https://github.com/github/spec-kit ; commands:
  https://github.github.io/spec-kit/reference/agentic-sdd.html
- OpenSpec: https://github.com/Fission-AI/OpenSpec ; concepts:
  https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md
- Kiro specs: https://kiro.dev/docs/specs/ ; EARS:
  https://en.wikipedia.org/wiki/Easy_Approach_to_Requirements_Syntax
- RFC 2119: https://www.rfc-editor.org/rfc/rfc2119 ; RFC 8174:
  https://www.rfc-editor.org/rfc/rfc8174
- ISO/IEC/IEEE 29148: https://www.iso.org/standard/72089.html ; verification and validation:
  https://en.wikipedia.org/wiki/Software_verification_and_validation ;
  https://sebokwiki.org/wiki/Verification_(glossary)
- Interface control document: https://en.wikipedia.org/wiki/Interface_control_document
- Rust RFC template: https://github.com/rust-lang/rfcs/blob/master/0000-template.md
- KEP template: https://github.com/kubernetes/enhancements/blob/master/keps/NNNN-kep-template/README.md
- PEP 1: https://peps.python.org/pep-0001/
- ADR (Nygard): https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions ;
  MADR: https://adr.github.io/madr/
- Testing vs checking (Bach and Bolton): https://www.satisfice.com/blog/archives/856
- ISTQB glossary: https://glossary.istqb.org/ ; smoke testing:
  https://en.wikipedia.org/wiki/Smoke_testing_(software)
- OpenAI Evals: https://github.com/openai/evals
- Scrum Guide: https://scrumguides.org/scrum-guide.html
- Spike (XP): https://www.oreilly.com/library/view/extreme-programming-installed/0201708426/0201708426_ch06lev1sec3.html
- Brooks, "Plan to throw one away": https://en.wikipedia.org/wiki/The_Mythical_Man-Month
- Fowler, Sacrificial Architecture: https://martinfowler.com/bliki/SacrificialArchitecture.html ;
  Technical Debt Quadrant: https://martinfowler.com/bliki/TechnicalDebtQuadrant.html
- Spolsky, Things You Should Never Do: https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/
- Icebox: https://thoughtbot.com/blog/the-icebox-is-where-stories-go-to-die ;
  https://pivotaltracker.com/help/articles/terminology
- Google SRE, postmortem culture: https://sre.google/sre-book/postmortem-culture/
- PMBOK lessons learned register (secondary): https://pmstudycircle.com/lessons-learned-register/
- Semantic Versioning: https://semver.org/ ; CalVer: https://calver.org/
- Keep a Changelog: https://keepachangelog.com/en/1.1.0/
- Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
- Changesets: https://github.com/changesets/changesets ;
  https://github.com/changesets/changesets/blob/main/docs/detailed-explanation.md
- release-please manifest: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
- Reproducible builds: https://reproducible-builds.org/docs/definition/
- SLSA provenance: https://slsa.dev/spec/v1.0/provenance
- MLflow tracking: https://mlflow.org/docs/latest/ml/tracking/

## Metadata

- Written 2026-10-10 for the mantra "where a field has a well-built term, use it"
  (`mantras/MANTRAS.md`, "Unify and simplify").
- Our words were collected from `CLAUDE.md`, `mantras/`, `prototype2/VERSIONING.md`, and the
  f4 and f5 process files.
- Not verified at a primary source: the ISTQB wording (taken from copies of the glossary), the
  PMBOK wording (secondary), ISO 29148's document names (from memory of the standard), and the
  "Known Issues" heading as a vendor convention.
