# Kinds of change and the check for each

## Answer: the recommended kinds and checks for section 2.1

Instrumentation is a kind of its own. The alternative path is not a kind. It is a technique
that a change of any kind can use, and it adds checks of its own.

The kind names what the change does to M.f. The check decides, with a pass or a fail, whether
the change did that and nothing else. Every number below is either taken from the cited source
or written into the proposal before the run. A check without its numbers fails proposal review.

"Tests" below means the checks M.f already has. For code they are tests. For a prompt they are
evals, each run k times, with k written in the proposal. A prompt change takes the kind of its
intent; only the way its tests run differs.

1. `feat`: new behaviour. Every acceptance scenario added in the delta has a test. That test
   fails on v and passes on v+1. Every test that passed on v passes on v+1.
   *Source:* Conventional Commits; SWE-bench's FAIL_TO_PASS and PASS_TO_PASS (applied to a
   feature: ours).
2. `fix`: a defect corrected. At least one test fails on v and passes on v+1. Every test that
   passed on v passes on v+1.
   *Source:* SWE-bench ("a task is considered solved if all tests across FAIL_TO_PASS and
   PASS_TO_PASS pass"); LLVM ("required to create test cases for any bugs fixed").
3. `refactor`: structure changed, behaviour not. Every test that passed on v passes on v+1, and
   the change edits no existing test. Where tests are missing, characterization tests are
   added first, as a separate `test` change.
   *Source:* Fowler's definition of refactoring; Feathers' characterization tests; LLVM's
   "NFC" ("No functional change"). That "edits no existing test" is the mechanical form of
   "unchanged tests" is ours.
4. `perf`: faster or cheaper, behaviour not changed. The refactor check, plus a measurement.
   v and v+1 run on the same items, interleaved, at least 10 runs each (20 where affordable),
   with the run count fixed before the first run. The claimed gain counts only if the
   Mann-Whitney U test gives p < 0.05 and the change is outside a stated noise band. A profile
   names the limiting factor.
   *Source:* benchstat (10–20 runs, interleave, fix the count, alpha 0.05, U test); criterion
   (noise threshold, default ±2%); Google Benchmark compare.py ("no less than 9"
   repetitions); Gregg's active benchmarking.
5. `instr` (instrumentation): logs, metrics, traces, run-record fields or counters added or
   changed. Three checks.
   - Behaviour unchanged: the refactor check. For a model, the inputs sent to the model on the
     same items are identical between v and v+1 (ours: a golden-master check on model inputs).
   - Signals as declared: the proposal lists each new signal with its name, the event that
     emits it, and its fields. A run on the stated items shows each declared signal in the run
     record with those fields.
   - A signal that a reader already uses (a dashboard, the run reviewer) is not renamed or
     removed. If it is, the change is breaking and carries `!`.
   *Source:* OpenTelemetry error handling ("lose telemetry data rather than have the library
   significantly change the behavior"); OpenTelemetry Weaver live-check (emitted signals
   compared with a declared registry); OpenTelemetry telemetry stability (adding signals is
   "additive, non-breaking"; stable telemetry may not change); gitmoji, which gives logs their
   own entry.
6. `docs`: documentation only. The diff touches no file outside documentation.
   *Source:* Angular and commitlint ("Documentation only changes").
7. `test`: tests only. The diff touches no file outside tests. Each new test passes on v.
   *Source:* Angular and commitlint ("Adding missing tests or correcting existing tests"). The
   pass-on-v rule is ours.
8. `build`: build system or dependencies. The build succeeds from a clean checkout, and every
   test that passed on v passes on v+1.
   *Source:* Angular and commitlint ("Changes that affect the build system or external
   dependencies"). The check is ours.
9. `!` (breaking), added to any kind: the delta names each contract that changes, and each
   known consumer is migrated before the old form is removed (expand, migrate, contract).
   *Source:* Conventional Commits (`!` maps to MAJOR); Fowler's parallel change.

**The alternative path, used within any kind.** The change builds a second path beside the
existing one, behind a switch. It names its purpose: comparison or transition. It adds three
checks to the checks of its kind.
- Default unchanged: with the switch off, every test that passed on v passes on v+1.
  *Source:* Hodgson: test "the fall-back configuration" with the new toggles off.
- Comparison with stated conditions: both paths run on the same items in the same period. The
  proposal states, before the run, the metrics, the success condition, the failure condition,
  and how many failed measurements stop the run. A comparison path (for checking a rewrite)
  passes with zero unexplained mismatches over the stated items; each known difference is
  listed by name. *Source:* Scientist (mismatches recorded, `ignore` for known differences);
  GitHub's rewrite ran "for 24 hours, and with no mismatches nor slow cases"; Argo Rollouts
  (`successCondition`, `failureLimit`; on failure the rollout aborts); Flagger (`threshold`:
  "max number of failed metric checks before rollback"); Google SRE (canary compared with a
  control at the same time, "no more than a dozen" metrics); online experiments add a sample
  ratio check (Kohavi et al.).
- Removal planned: the proposal names the follow-up change that removes the losing path, and
  an expiry date. After the date, a check fails while both paths exist.
  *Source:* Fowler's branch by abstraction ("Once the flawed supplier isn't needed, we can
  delete it"); parallel change ("If the contract phase is not executed you might end up in a
  worse state than you started"); Hodgson (expiration dates and "time bombs").

The switch-over and the removal are changes of their own. The switch-over takes the kind of the
underlying change. The removal of the old path is a `refactor`, since the default path no longer
uses it. *(Inferred from branch by abstraction and parallel change, which treat these as
separate steps.)*

## 1. How established taxonomies classify the two kinds

**Conventional Commits and its extended types.** The specification defines `feat` and `fix`.
It "recommends `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`,
and others." commitlint's config-conventional allows: build, chore, ci, docs, feat, fix, perf,
refactor, revert, style, test. None of these names instrumentation or an alternative path.
`chore` is "Other changes that don't modify src or test files". Instrumentation modifies source
files, so it does not fit `chore` by that definition. Projects that need it use a scope, such as
`feat(telemetry)`. *(This last point is common practice seen in projects, not a documented
rule.)*

**gitmoji.** gitmoji gives both kinds their own entries.
- Instrumentation: `:loud_sound:` "Add or update logs." and `:mute:` "Remove logs." (semver:
  none); `:chart_with_upwards_trend:` "Add or update analytics or track code." (patch);
  `:stethoscope:` "Add or update healthcheck." (none).
- Alternative path: `:triangular_flag_on_post:` "Add, update, or remove feature flags."
  (patch); `:alembic:` "Perform experiments." (patch).
gitmoji is the only commit taxonomy surveyed that gives instrumentation a kind of its own.

**Keep a Changelog.** Its types are Added, Changed, Deprecated, Removed, Fixed, Security. They
describe what a user of the release sees. Neither kind has an entry. *(Inferred: a new log the
user does not read, or a dark path, would not appear in the changelog; a signal a user does read
would be Added or Changed.)*

**ITIL and ISO/IEC 14764.** ITIL sorts changes by risk and approver (standard, normal,
emergency). ISO/IEC 14764 sorts maintenance by motive (corrective, adaptive, perfective,
preventive). Neither names instrumentation or an alternative path. *(Inferred: adding
monitoring would be perfective or preventive by motive.)*

**OpenTelemetry.** OpenTelemetry treats emitted telemetry as an interface. Adding metrics,
spans, events, log records or attributes is "considered additive, non-breaking changes and are
always allowed". Stable instrumentations "are prohibited from changing any produced telemetry"
outside the published conventions. Weaver's guidance is to "treat telemetry like a public
API": "If you wouldn't break your app's API between releases, don't break your telemetry
either." Its `live-check` compares the signals an application emits against a declared
registry. Telemetry must not alter the application: implementations "MUST NOT throw unhandled
exceptions at runtime", and users "would prefer to lose telemetry data rather than have the
library significantly change the behavior."

**Feature toggles (Hodgson, on Fowler's site).** Four categories. Release toggles "allow
incomplete and un-tested codepaths to be shipped to production as latent code". Experiment
toggles "are used to perform multivariate or A/B testing." Ops toggles "control operational
aspects of our system's behavior." Permissioning toggles "change the features or product
experience that certain users receive." Toggles are "inventory which comes with a carrying
cost". Release toggles "should generally not stick around much longer than a week or two."
Some teams put "expiration dates" on toggles, or "time bombs" that fail a test when a toggle
outlives its date.

**Branch by abstraction (Fowler).** A technique "that allows you to release the system regularly
while the change is still in-progress." The rule is: "Ensure that the system builds and runs
correctly at all times." With a toggle one can "run the new supplier in test environments and
compare its behavior to the flawed supplier." It ends: "Once the flawed supplier isn't needed,
we can delete it."

**Parallel change (Fowler).** Also "expand and contract": "a pattern to implement
backward-incompatible changes to an interface" in three phases. Expand: "augment the interface
to support both the old and the new versions." Migrate: "update all clients". Contract: "remove
the old version".

**Strangler fig (Fowler).** "A gradual process of modernization", with "transitional
architecture" that lets new and legacy systems coexist and "will go away once the modernization
is complete."

**Dark launching (Fowler).** "Taking a new or changed back-end behavior and calling it from
existing users", "to assess the additional load and performance impacts". In the parallel
variant both paths run and "only one answer" returns.

**Scientist (GitHub).** "A Ruby library for carefully refactoring critical paths." The `use`
block is the control and the `try` block the candidate. `run` "will always return whatever the
`use` block returns." It records durations, mismatches and exceptions. It "is only safe for
wrapping methods that aren't changing data."

**Canarying and progressive rollout.** Google SRE: "a partial and time-limited deployment of a
change in a service and its evaluation", compared against a control at the same time, because
"it is difficult to assess degradation of performance with before/after evaluation." Google's
feature-flag frameworks can "Independently revert each such change immediately". Flagger's
traffic mirroring copies each request to both versions and "The response from the canary is
discarded"; it "should be used for requests that are idempotent".

**Finding.** Instrumentation is a kind of its own in gitmoji and is treated as an interface by
OpenTelemetry. Every other taxonomy is silent on it. The alternative path is a technique in
every source. Scientist serves refactoring. Branch by abstraction and strangler fig serve large
replacements. Parallel change serves breaking interface changes. Canarying applies to any
change. Only gitmoji gives flags and experiments a commit entry of their own.

## 2. The established check for each kind

**Fix.** SWE-bench requires "at least one test where its status changes from a fail to pass",
and pass-to-pass tests "ensure that the revision does not break or violate any existing
expected behavior". "A task is considered solved if all tests across FAIL_TO_PASS and
PASS_TO_PASS pass." LLVM: "Developers are required to create test cases for any bugs fixed and
any new features added."

**Refactor.** Fowler defines refactoring as a change "without changing its observable
behavior." LLVM tags such commits "NFC": "No functional change … a pure refactoring/cleanup."
Where tests are missing, Feathers' characterization tests record what the code does now, not
what it should do, so that later changes can be compared against it.

**Performance.** benchstat: run each benchmark "at least 10 times", ideally 20; "Pick a number
of benchmark runs … and stick to it"; interleave before and after runs; it uses "the
Mann-Whitney U-test for A/B comparisons" with "an ɑ threshold of 0.05"; do not "simply rerun
your benchmarks until it reports a significant change". criterion: results within
`±noise_threshold` "are assumed to be noise"; the default is ±2%; its verdicts are "Performance
has improved", "Performance has regressed", "No change in performance detected", "Change within
noise threshold". Google Benchmark's compare.py uses the U test and "requires LARGE (no less
than 9) number of repetitions". hyperfine runs "at least 10" runs with warmup and outlier
detection.

**Prompt and model changes.** Anthropic: regression evals ask "Does the agent still handle all
the tasks it used to?" and "should have a nearly 100% pass rate"; pass^k "measures the
probability that all k trials succeed"; "we run multiple trials"; LLM graders "should be closely
calibrated with human experts". Anthropic's statistics guidance for comparing two versions:
"Analyze paired differences" on the same questions, report mean difference, standard error and
confidence interval, cluster standard errors on related items, and use power analysis to set
the number of items. OpenAI: "run evals on every change"; "Include a pass/fail threshold in
addition to the numerical score"; "Use human feedback to calibrate automated scoring." Neither
source states "no previously passing case may fail" as a rule. The nearest stated rule is
Anthropic's "nearly 100%". *(The recommendation above makes it exact: a case counts as passing
on v only if it passed in all k trials, and each such case must pass on v+1. This exact form is
ours, built from pass^k and SWE-bench's PASS_TO_PASS.)*

**Instrumentation.** No source gives a per-change check under that name. The pieces exist.
Behaviour unchanged: OpenTelemetry's error-handling rules and LLVM's NFC. Signals as specified:
Weaver's live-check against a registry, and `weaver registry check` on each registry change,
whose policies block "removing existing elements". Breaking telemetry: OpenTelemetry's stability
rules. *(Combining them into one check is ours.)*

**Alternative path.**
- Parallel run: Scientist records every mismatch; known differences are named in `ignore`
  blocks, which "are only called if the values don't match". GitHub's own rewrite ran until a
  24-hour full-traffic run had "no mismatches nor slow cases".
- Progressive delivery: Argo Rollouts' AnalysisTemplate example sets `successCondition:
  result[0] >= 0.95`, `interval: 5m`, `failureLimit: 3`; "The failed analysis causes the Rollout
  to abort, setting the canary weight back to zero". "Inconclusive runs causes a rollout to
  become paused". Flagger's example: request success rate `min: 99`, request duration `max:
  500`, and a `threshold` of failed checks, after which it "rolls back the canary".
- Canarying: Google SRE compares the canary with a control in the same period, picks "no more
  than a dozen" metrics, and requires that changes in them be "clearly attributable to the
  change". The canary "should be sizeable and last long enough to be representative".
- A/B experiments: guardrail metrics must not significantly degrade even when the main metric
  improves (Dmitriev et al., KDD 2017). Sample ratio mismatch, "the situation when the observed
  sample ratio in the experiment is different from the expected", signals a broken experiment
  (Fabijan et al., KDD 2019). Experiment toggles stay fixed "long enough to generate
  statistically significant results" (Hodgson).
- Toggle hygiene: test the production configuration and "the fall-back configuration";
  expiration dates and time bombs (Hodgson).

## Sources

- Conventional Commits 1.0.0: https://www.conventionalcommits.org/en/v1.0.0/
- commitlint config-conventional: https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional
- Angular commit types: https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md
- gitmoji list: https://github.com/carloscuesta/gitmoji/blob/master/packages/gitmojis/src/gitmojis.json
- Keep a Changelog 1.1.0: https://keepachangelog.com/en/1.1.0/
- ISO/IEC 14764 and Swanson (secondary): https://en.wikipedia.org/wiki/Software_maintenance
- ITIL change types (secondary): https://itsm.tools/change-enablement/
- Hodgson, Feature Toggles: https://martinfowler.com/articles/feature-toggles.html
- Fowler, Branch by Abstraction: https://martinfowler.com/bliki/BranchByAbstraction.html
- Fowler, Parallel Change: https://martinfowler.com/bliki/ParallelChange.html
- Fowler, Strangler Fig: https://martinfowler.com/bliki/StranglerFigApplication.html
- Fowler, Dark Launching: https://martinfowler.com/bliki/DarkLaunching.html
- Fowler, definition of refactoring: https://martinfowler.com/bliki/DefinitionOfRefactoring.html
- Characterization test: https://en.wikipedia.org/wiki/Characterization_test
- LLVM Developer Policy: https://llvm.org/docs/DeveloperPolicy.html ; Lexicon (NFC): https://llvm.org/docs/Lexicon.html
- SWE-bench paper: https://arxiv.org/abs/2310.06770
- GitHub Scientist: https://github.com/github/scientist ; "Move fast and fix things": https://github.blog/engineering/move-fast/
- Google SRE Workbook, canarying: https://sre.google/workbook/canarying-releases/
- Google SRE Book, reliable product launches: https://sre.google/sre-book/reliable-product-launches/
- Argo Rollouts analysis: https://argo-rollouts.readthedocs.io/en/stable/features/analysis/
- Flagger: https://docs.flagger.app/usage/how-it-works ; https://docs.flagger.app/usage/deployment-strategies
- Kohavi, Tang, Xu, Trustworthy Online Controlled Experiments, ch. 21: https://www.cambridge.org/core/books/trustworthy-online-controlled-experiments/sample-ratio-mismatch-and-other-trustrelated-guardrail-metrics/8DBB0F59AC7729D7BC6B94690DB9CCD5
- Dmitriev et al., KDD 2017 (summary): https://blog.acolyer.org/2017/09/25/a-dirty-dozen-twelve-common-metric-interpretation-pitfalls-in-online-controlled-experiments/
- Fabijan et al., KDD 2019, sample ratio mismatch: https://www.lukasvermeer.nl/publications/papers/2019/07/25/diagnosing-sample-ratio-mismatch-in-online-controlled-experiments.html
- OpenTelemetry telemetry stability: https://opentelemetry.io/docs/specs/otel/telemetry-stability/
- OpenTelemetry error handling: https://opentelemetry.io/docs/specs/otel/error-handling/
- OpenTelemetry performance: https://opentelemetry.io/docs/specs/otel/performance/
- OpenTelemetry Weaver: https://opentelemetry.io/blog/2025/otel-weaver/
- benchstat: https://pkg.go.dev/golang.org/x/perf/cmd/benchstat
- criterion output: https://bheisler.github.io/criterion.rs/book/user_guide/command_line_output.html
- Google Benchmark tools: https://github.com/google/benchmark/blob/main/docs/tools.md
- hyperfine: https://github.com/sharkdp/hyperfine
- Gregg, active benchmarking: https://www.brendangregg.com/activebenchmarking.html
- Anthropic, evals for agents: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- Anthropic, statistical approach to evals: https://www.anthropic.com/research/statistical-approach-to-model-evals
- OpenAI, evaluation best practices: https://developers.openai.com/api/docs/guides/evaluation-best-practices

## Metadata

- Written 2026-10-10 for section 2.1 of the plan, to classify the two kinds left open there.
  It extends section 1 of `survey-development-flow.md`.
- Not verified at a primary source: the Kohavi book chapter and Dmitriev et al. (abstract and
  summary only); ITIL and ISO/IEC 14764 wording (secondary); the SWE-bench Verified page
  (blocked; the original paper was used).
- Marked as ours in the body: the name `instr`; the golden-master check on model inputs; the
  "edits no existing test" form of the refactor check; the exact pass^k form of the regression
  eval rule; the kinds of the switch-over and removal changes.
