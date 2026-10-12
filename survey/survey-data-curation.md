# Survey: curating S's data from iteration to project to shared

Survey date: 2026-10-12.

This survey covers how S's eight data types (`S/specs/data.md`) are collected, de-duplicated,
cleansed and handed up the layers. It does not repeat three earlier surveys:
`survey-simulated-reviewer.md` (choosing, storing and keeping the person's examples current,
Cohen's kappa), `survey-reverse-seed-dataset.md` (building use cases, recency cutoffs, canaries)
and `survey-layered-templates.md` (sync, upstream, pull requests to `shared`).

"Inference" marks a step that is ours and not taken from a source.

## Answer: the curation pipeline, per leg

Established practice runs the same five stages on both legs: collect with provenance, remove
exact duplicates, cluster near duplicates, cleanse, then promote through a review gate into a
versioned dataset. The two legs differ in one thing. Iteration to project is a move between
private stores. Project to `shared` is a publication, so the gate there is a privacy and licence
gate, not only a quality gate.

**The role.** S needs one new role, the **curator**. The curator does the work; the decision
maker approves it. This is the data-governance split between a data steward, who runs quality
work, and an owner, who holds accountability (DAMA-DMBOK, as summarised by secondary sources).
It also keeps S's rule that no author reviews its own artifact. For the `shared` leg, the merge
is done by `shared`'s maintainer through a pull request, the inner-source pattern already
adopted in `survey-layered-templates.md`. Inference: the curator is an agent like S's other
roles, and its two legs are the two halves of the upstream workflow.

**Leg 1: iteration to project.** Run at the end of a generation, and whenever needed, off the
critical path.

1. **Collect.** Every entry already carries `id`, `by`, `status`, `decided`. Add its origin: the
   layer and id it came from and a content hash. Langfuse links each dataset item to its source
   trace (`source_trace_id`). MLflow records each assessment's source type (HUMAN, LLM_JUDGE,
   CODE), source id and timestamps. Inference: S's `by` already covers the source; the origin
   and hash are the missing fields.
2. **Exact de-duplication.** Hash a canonical form of each entry: sorted keys, normalised
   whitespace and Unicode, without `id`, `status` and timestamps. Same hash, same entry; keep one.
   (Bloom-filter and hash dedup in text-dedup, NeMo Curator, datatrove.)
3. **Near-duplicate clustering.** Compare the text fields. At web scale this is MinHash with LSH
   (Jaccard 0.7 to 0.8), SimHash (3 differing bits of 64) or embeddings (cosine ≥ 0.93 in NeMo
   Curator's example). Inference: at S's size, tens to hundreds of entries per generation, every
   pair can be compared directly; no LSH index is needed.
4. **Merge or keep.** Two entries that say the same thing from different sources are agreement,
   not waste. Keep each source's label and count them, then derive a consensus (cleanlab's
   CROWDLAB; the disagreement literature, Uma et al. 2021, finds soft labels from many judges beat
   a single aggregated label when judges are good). Merge only true copies of one judgement.
   When the person reverses an earlier verdict, keep the later one and retire the earlier one
   (PersonaMem, in `survey-simulated-reviewer.md`).
5. **Cleanse.** Scan for secrets in run records and code reviews (detect-secrets, with a baseline
   file and a pre-commit hook). Flag likely label errors for review, never drop them
   automatically: in Northcutt et al. only 51% of algorithmically flagged labels were real
   errors. Check that the blind re-label set and held-out use cases do not leak into the
   examples the simulated reviewers learn from.
6. **Promote.** The curator puts candidates in a review queue; the decision maker approves each
   (LangSmith and Langfuse annotation queues; LangSmith's "Add to Dataset" from a queue item).
   Approved entries are committed to the project's `S/data/`, and the commit is the dataset
   version (LangSmith and Langfuse create a version on every change; DVC and git pin versions).

**Leg 2: project to `shared`.** Run when content has proved general.

1. **Select.** Only entries useful to every project: generalisable findings, review rules,
   decision patterns, format examples. Inference: most use cases and run records stay in the
   project.
2. **Generalise.** Rewrite each entry without project specifics, then check that it still does
   its job: a generalised finding must still let the reviewer catch the fault (ours, from
   `survey-layered-templates.md`). Clio does the same for usage data: an LLM summary that omits
   private details, plus a minimum count before a pattern is shown.
3. **Withhold the person's words.** Do not publish them verbatim. Removing names is not enough:
   LLMs inferred personal attributes from text with up to 85% top-1 accuracy, and the authors
   found "text anonymization and model alignment" "currently ineffective" (Staab et al. 2023).
   Inference: what goes up is a rewrite, recorded with the rewriter in `by` and `made_up: true`,
   never as the person's words; the spec's rule on words already requires this.
4. **Scan.** Run PII detection (Presidio) and secret detection (detect-secrets) on the result.
   Presidio itself says "there is no guarantee that Presidio will find all sensitive
   information", so the scan supports the review; it does not replace it.
5. **Gate.** A pull request to `shared`, with the scan output attached, reviewed and merged by
   `shared`'s maintainer, then a release tag. This is write-audit-publish: write on a branch,
   audit there, merge to main only if the checks pass (lakeFS pre-merge hooks).
6. **Document and license.** Each data folder's README states what the data is, how it was made,
   what was withheld, and its licence (Datasheets for Datasets). Licences are often missing on
   public datasets: the Data Provenance audit found "license omission of 70%+".

**Cost.** All of this is cheap next to one f run. Hashing, MinHash, Presidio and detect-secrets
take seconds on a laptop CPU for hundreds of entries. Inference, from the cost model in
`survey-reverse-seed-dataset.md` (about 1,460 input tokens/s, 20 output tokens/s on our local
model): a judgement of one candidate pair (2k tokens in, 100 out) takes about 6 s; a
generalising rewrite (1.5k in, 400 out) about 20 s per entry. A measured run would prove these
wrong.

### Per data type

Each line gives the leg-1 rule, then the leg-2 rule. Every rule is an inference applying the
practice above to the type's fields in `S/specs/data.md`.

- **Use cases.** Leg 1: exact dedup on the canonical `seed`; near duplicates by seed text; keep
  the one with the fuller `rubric`, retire the other. Keep held-out and blind re-label use cases
  apart. Leg 2: rarely; only a rewritten seed with its rubric, as a format example.
- **Run records.** Leg 1: not deduplicated (each run is an event). Keep those that a grade or a
  run review cites; scan traces for secrets. Leg 2: never verbatim; trace content is sensitive by
  default (OpenTelemetry makes message capture opt-in). Only made-up examples go up.
- **Run grades.** Leg 1: one grader grading one run twice with the same result is a copy; merge.
  Different graders on one run are agreement; keep all and compute consensus and agreement.
  Flag grades where the simulated user and the person disagree. Leg 2: no raw grades; agreement
  statistics may go up.
- **Run reviews.** Leg 1: near-duplicate findings across runs merge into one finding that lists
  every symptom and counts occurrences. Rejected findings stay, as the spec says. Leg 2: the
  generalised finding, checked to still catch the fault.
- **Proposals.** Leg 1: near-duplicate proposals across steps merge, keeping each decision on
  them. Leg 2: only the pattern of an approved and done proposal, generalised.
- **Proposal reviews.** Leg 1: travel with their proposal; deduplicate only exact copies. Leg 2:
  only as part of a generalised proposal pattern.
- **Decisions.** Leg 1: never merge decisions made at different times; a later decision that
  reverses an earlier one retires it. Leg 2: the person's reasons are withheld; only general
  rules derived from many decisions go up, rewritten.
- **Code reviews.** Leg 1: near-duplicate comments group by `rule`, with counts. Scan for secrets.
  Leg 2: rule-level generalisations; project code is withheld.

## 1. Collection

**LangSmith annotation queues.** https://docs.langchain.com/langsmith/annotation-queues.
"Annotation queues give human reviewers a focused workflow for attaching feedback to specific
runs or threads." Each queue has feedback keys, the rubric shown on every item. A setting fixes
"the number of reviewers that must mark an item as Done for it to be removed from the queue".
Reviewers cannot see each other's feedback. A reviewer can correct a run and use "Add to
Dataset". Pairwise queues show two runs side by side. Automation rules filter runs, for example
by a feedback score, and add them to a dataset or a queue; with "Use corrections" the corrected
output becomes the dataset example (https://docs.smith.langchain.com/how_to_guides/monitoring/rules).
Prescribes: queue, then human approval, then dataset. Local cost: none if self-built; LangSmith
itself is a hosted service.

**Langfuse datasets and annotation queues.**
https://langfuse.com/docs/evaluation/evaluation-methods/annotation-queues,
https://langfuse.com/docs/evaluation/experiments/datasets. Queues are "built for domain experts
to add scores and comments to traces, observations or sessions", and need a score config. "A
common workflow is to select production traces where the application did not perform as
expected." Items keep `source_trace_id`. "Every add, update, delete, or archive of dataset items
produces a new dataset version." Archived items are removed "from future experiment runs".
Langfuse is open source and self-hostable.

**Argilla task distribution.** https://docs.argilla.io/latest/how_to_guides/distribution/. A
record is `completed` "when it has the required number of responses with submitted status"
(`min_submitted`, default 1). Responses are `draft`, `submitted` or `discarded`. Prescribes:
explicit statuses per response and a minimum count of judgements per item.

**MLflow feedback.** https://mlflow.org/docs/latest/genai/concepts/feedback/. Feedback has a
`name`, `value`, `rationale`, `source` (type HUMAN, LLM_JUDGE or CODE, plus an id), `metadata`,
creation and update times, and the trace or span it attaches to. "MLflow tracks metadata and
revision history of the feedbacks."

**OpenTelemetry GenAI conventions.**
https://github.com/open-telemetry/semantic-conventions-genai (moved there from the main
semantic-conventions repository; status Development). The `gen_ai.evaluation.result` event
carries `gen_ai.evaluation.name` (required), `score.value`, `score.label` and `explanation`, and
"SHOULD be parented to GenAI operation span being evaluated". Content attributes such as input
and output messages are `Opt-In`; for some, "Instrumentations SHOULD NOT capture this attribute
by default", and output messages are "likely to contain sensitive information including
user/PII data".

**What metadata to keep.** Across these tools: the source (who or what judged, and its kind),
a link to the source run or span, timestamps, a status, and a dataset version on every change.
S's spec already has `by`, `status`, `decided`. Inference: add the origin (layer and source id)
and a content hash, so that exact dedup and promotion can be traced.

## 2. De-duplication

**Why.** Lee et al., "Deduplicating Training Data Makes Language Models Better" (2021),
https://arxiv.org/abs/2107.06499: deduplicated models "emit memorized text ten times less
frequently", and train-test overlap affected "over 4% of the validation set of standard
datasets". For S, the second point matters most: duplicates between learning examples and
evaluation items inflate agreement scores (inference).

**Exact.** Hash a normalised form. text-dedup offers Bloom-filter and suffix-array exact dedup
(https://github.com/ChenghaoMou/text-dedup). datatrove has sentence-level exact dedup and
ExactSubstr (https://github.com/huggingface/datatrove). Cost: negligible.

**Near duplicates by text.** MinHash with LSH estimates Jaccard similarity of shingles.
text-dedup's example: 5-gram shingles, 240 permutations, threshold 0.7. NeMo Curator's fuzzy
dedup uses 24-character n-grams, 20 bands of 13 hashes, and a Jaccard threshold of 0.8 for
false-positive checks
(https://docs.nvidia.com/nemo/curator/26.02/curate-text/process-data/deduplication/fuzzy.html).
SimHash (Charikar; Manku, Jain and Das Sarma, WWW 2007,
https://doi.org/10.1145/1242572.1242592) compares fingerprints by differing bits; text-dedup's
example uses 64 bits and 3 bits of difference. Cost: seconds on a CPU at our size.

**Near duplicates by meaning.** SemDeDup (Abbas et al. 2023, https://arxiv.org/abs/2303.09540)
embeds items and removes pairs above a cosine threshold. On LAION it "can remove 50% of the data
with minimal performance loss". NeMo Curator's semantic dedup example uses eps 0.07, that is
cosine ≥ 0.93
(https://docs.nvidia.com/nemo/curator/latest/curate-text/process-data/deduplication/semdedup.html).
Cost: one small embedding model, seconds for hundreds of entries on a CPU (inference).
Paraphrased findings, which S will produce most, are caught only by this method or by an LLM
judgement (inference).

**Merge or keep.** Web dedup keeps one copy. Label data is different: repeated judgements of one
item are evidence. cleanlab's CROWDLAB returns "a consensus label for each example", "a quality
score for each consensus label" and "an overall quality score for each annotator"
(https://docs.cleanlab.ai/stable/tutorials/multiannotator.html). Uma et al., "Learning from
Disagreement: A Survey", JAIR 2021 (https://jair.org/index.php/jair/article/view/12752): with
many good judgements per item, training on soft labels beat aggregated or gold labels; otherwise
both together did best. Prescribes: count agreement, keep disagreement.

## 3. Cleansing

**Label noise.** Confident learning flags labels that disagree with a model's predictions.
Northcutt et al., "Pervasive Label Errors in Test Sets" (2021), https://arxiv.org/abs/2103.14749:
"an average of at least 3.3% errors across the 10 datasets"; of the flagged candidates, "51% ...
are indeed erroneously labeled". So flags go to a reviewer. Library: cleanlab. Cost: needs only
the predicted probabilities, which S has as the simulated reviewers' grades (inference).

**Consistency between graders.** Cohen's kappa against the person's own consistency is set in
the plan and `survey-simulated-reviewer.md`. For more than two graders, Krippendorff's alpha;
Krippendorff advises relying on data with α ≥ 0.800 and drawing only tentative conclusions for
0.667 ≤ α < 0.800 ("Computing Krippendorff's Alpha-Reliability",
https://repository.upenn.edu/asc_papers/43).

**PII.** Microsoft Presidio (https://presidio.dataprivacystack.org/): an analyzer for "PII
identification in text" and an anonymizer that applies operators (replace, redact, hash and
others) to what is found. It warns "there is no guarantee that Presidio will find all sensitive
information". Cost: CPU, fast. TAB, the Text Anonymization Benchmark (Pilán et al. 2022,
https://arxiv.org/abs/2202.00443), separates anonymisation, which prevents disclosure about a
person, from de-identification, "limited to the detection of predefined semantic categories".
Staab et al., "Beyond Memorization" (2023, https://arxiv.org/abs/2310.07298): LLMs inferred
personal attributes at "up to 85% top-1", and current text anonymisation was ineffective
against this.

**Secrets.** detect-secrets (https://github.com/Yelp/detect-secrets): regex, entropy and keyword
plugins, a baseline file of known findings, an audit step where "analysts ... label results",
and a pre-commit hook. Cost: seconds.

**Contamination.** Recency and canaries for use cases are in `survey-reverse-seed-dataset.md`.
Inside S the risk is leakage between sets: the blind re-label set, held-out use cases and the
examples the reviewers learn from. Inference: check exact and near-duplicate overlap between
these sets with the same tools as section 2.

**Quality filters.** Large pipelines (NeMo Curator, datatrove, Data-Juicer) chain heuristic and
model-based filters. Inference: S's entries are few and structured, so the filters S needs are
schema checks (every required field, valid status) and the label review above.

## 4. Hand-up and promotion

**Golden sets from production.** Anthropic, "Demystifying evals for AI agents"
(https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents): "20-50 simple tasks
drawn from real failures is a great start"; "Converting user-reported failures into test cases
ensures your suite reflects actual usage"; "An eval suite is a living artifact that needs
ongoing attention and clear ownership". LangSmith and Langfuse promote production runs to
datasets through queues (section 1).

**Versioning.** LangSmith: "Any time you add, update, or delete examples in your dataset, a new
version of your dataset is created", and a version can be tagged, for example "prod", and
evaluated against (https://docs.langchain.com/langsmith/manage-datasets). DVC keeps data hashes
in small `.dvc` files in git and the data in a cache or remote
(https://doc.dvc.org/start/data-management/data-versioning). Hugging Face datasets are git
repositories loaded at a `revision`. Inference: S's data is small JSON in git, so a commit and a
tag already give these versions; `survey-layered-templates.md` reached the same conclusion.

**Review gates.** lakeFS's write-audit-publish: data is written on a branch, pre-commit and
pre-merge hooks check schema, format or PII, and a failing `pre-` hook blocks the merge to main
(https://docs.lakefs.io/guides/hooks/). Data contracts state "a dataset's structure, semantics,
quality expectations, and service commitments in code", owned by the producer, with each term
set to alert, block or quarantine (https://lakefs.io/blog/data-contracts/). Inference: S's
contract is `S/specs/data.md` plus each folder's README; the gate is a check that each promoted
entry meets it.

**Generalising for publication.** Clio (https://www.anthropic.com/research/clio) extracts
information "while omitting private details" and keeps "a minimum threshold for the number of
unique users or conversations" before a pattern is shown, with regular privacy audits. Given
Staab et al. (section 3), the established safe practice is to publish aggregates and rewrites,
not lightly edited originals.

**Licensing and documentation.** Datasheets for Datasets (Gebru et al.,
https://arxiv.org/abs/1803.09010): each dataset should come with a datasheet documenting "its
motivation", "composition, collection process, recommended uses". The Hugging Face dataset card
template has a "Personal and Sensitive Information" section that asks whether personal data is
present and how it was anonymised. The Data Provenance Initiative (Longpre et al. 2023,
https://arxiv.org/abs/2310.16787) audited over 1,800 datasets and found "license omission of 70%+
and error rates of 50%+". Prescribes: state the licence and what was withheld, per folder. The
choice of licence is the owner's.

## 5. Roles

**Data steward and owner.** DAMA-DMBOK2 defines stewardship as "the formalization of
accountability and responsibility for data and data assets on behalf of stakeholders" (quoted by
secondary sources; the book is not open). Stewards monitor and fix quality and document
meaning; owners hold accountability. In mature organisations stewardship is often embedded in
existing roles rather than a separate job (secondary sources).

**Curator, annotator, maintainer.** Annotators give labels (Argilla, Label Studio, LangSmith
queues). A curator selects and cleans. A dataset maintainer owns releases and the card. Inner
source's trusted committer is the maintainer role for a shared repository
(`survey-layered-templates.md`).

**What automation does, and what needs review.** From the sources above: hashing, near-duplicate
search, PII and secret scans, schema checks and versioning are automated. Three things need a
reviewer: label-error flags (half are false alarms in Northcutt et al.), PII results (Presidio
gives no guarantee), and anything published (anonymisation is not enough, Staab et al.).

**Agentic curation tools, 2025 to 2026.** DataFlow (Dec 2025, https://arxiv.org/abs/2512.16676):
about 200 operators and DataFlow-Agent, which "translates natural-language specifications into
executable pipelines via operator synthesis, pipeline planning, and iterative verification".
Data-Juicer (https://github.com/datajuicer/data-juicer) ships data-juicer-agents and recipes for
agent-log analysis. Both target large training corpora. Inference: for S's size, the curator is
better a plain agent with the steps above as a checklist than one of these frameworks.

**For S.** Inference: one new role, the curator, an agent, which runs both legs and writes a
report of what it merged, retired, flagged and withheld. The decision maker approves leg 1 in a
review queue. `shared`'s maintainer approves leg 2 by merging the pull request. The curator never
approves its own output.

## Sources

- LangSmith annotation queues: https://docs.langchain.com/langsmith/annotation-queues
- LangSmith automation rules: https://docs.smith.langchain.com/how_to_guides/monitoring/rules
- LangSmith dataset versions: https://docs.langchain.com/langsmith/manage-datasets
- Langfuse annotation queues: https://langfuse.com/docs/evaluation/evaluation-methods/annotation-queues
- Langfuse datasets: https://langfuse.com/docs/evaluation/experiments/datasets
- Argilla task distribution: https://docs.argilla.io/latest/how_to_guides/distribution/
- MLflow feedback: https://mlflow.org/docs/latest/genai/concepts/feedback/
- OpenTelemetry GenAI semantic conventions: https://github.com/open-telemetry/semantic-conventions-genai
- Lee et al. 2021, deduplication: https://arxiv.org/abs/2107.06499
- text-dedup: https://github.com/ChenghaoMou/text-dedup
- datatrove: https://github.com/huggingface/datatrove
- NeMo Curator fuzzy dedup: https://docs.nvidia.com/nemo/curator/26.02/curate-text/process-data/deduplication/fuzzy.html
- NeMo Curator semantic dedup: https://docs.nvidia.com/nemo/curator/latest/curate-text/process-data/deduplication/semdedup.html
- SemDeDup: https://arxiv.org/abs/2303.09540
- Manku, Jain, Das Sarma 2007, SimHash near duplicates: https://doi.org/10.1145/1242572.1242592
- cleanlab multi-annotator (CROWDLAB): https://docs.cleanlab.ai/stable/tutorials/multiannotator.html
- Uma et al. 2021, Learning from Disagreement: https://jair.org/index.php/jair/article/view/12752
- Northcutt et al. 2021, Pervasive Label Errors: https://arxiv.org/abs/2103.14749
- Krippendorff, Computing Krippendorff's Alpha-Reliability: https://repository.upenn.edu/asc_papers/43
- Presidio: https://presidio.dataprivacystack.org/
- TAB, Text Anonymization Benchmark: https://arxiv.org/abs/2202.00443
- Staab et al. 2023, Beyond Memorization: https://arxiv.org/abs/2310.07298
- detect-secrets: https://github.com/Yelp/detect-secrets
- Anthropic, Demystifying evals for AI agents: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- Anthropic, Clio: https://www.anthropic.com/research/clio
- DVC data versioning: https://doc.dvc.org/start/data-management/data-versioning
- lakeFS hooks: https://docs.lakefs.io/guides/hooks/
- lakeFS on data contracts: https://lakefs.io/blog/data-contracts/
- Datasheets for Datasets: https://arxiv.org/abs/1803.09010
- Data Provenance Initiative: https://arxiv.org/abs/2310.16787
- DataFlow: https://arxiv.org/abs/2512.16676
- Data-Juicer: https://github.com/datajuicer/data-juicer
