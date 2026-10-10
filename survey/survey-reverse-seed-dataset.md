# Survey: building f's item dataset by reverse generation

Survey date: 2026-10-10.

## Answer: how to build f's items

An item is a seed, a proper answer and a difficulty. Two published efforts have already built almost this, from papers to plans: Idea2Plan (Oct 2025) and Meta's "Training AI Co-Scientists using Rubric Rewards" (Dec 2025). The recipe below follows them. Each step names its source.

**Sourcing.** Take real material that already describes a finished system or study: papers, open-source projects with design docs, specs. Keep only material dated after the local model's training cutoff, or material that was never public. Idea2Plan drops ICML 2025 papers that had an arXiv version before the cutoff. ResearchBench keeps only papers from 2024 onward. Our own design documents and past f plans have never been public, so they are clean by construction.

**Reverse generation of the seed.** One LLM call reads the source and writes the seed. The seed states the goal and the problem in the first person. It removes method names, results and claims. This is Idea2Plan's step: o4-mini rewrites the abstract "in first person", dropping "method and dataset names, results, and performance claims". Meta's version writes "a self-contained research goal with constraints and key uncertainties". The general idea is instruction backtranslation (Humpback): a backward model p(x|y) writes the input for an existing output. Humpback's lesson applies: generate several candidates and keep only well-scored ones. Uncurated backtranslated data did not help; curated data did.

**The proper answer.** Keep the source as the proper answer. Do not judge f's plan by similarity to it. Derive a rubric from it instead: yes/no checks that any valid plan for this seed should pass. Tag each check with the level it belongs to (CEO proposal, EVP contract, manager design, worker task). Idea2Plan writes its rubric questions as "common desiderata" any valid plan should meet, "not exact matches". Meta drafts 15 items per goal and keeps the best 10. Rubrics written with the reference in hand beat rubrics written without it: 35.9% vs 32.0% on HealthBench (Rubrics as Rewards).

**Judging f's plan.** A judge answers each rubric check Yes or No. Score each level as the fraction passed, then average the levels. This is Idea2Plan's section score and macro-average. It judges one section per call, which fits a local model's context. Validate the judge once on a few human-labelled plans, as Idea2Plan JudgeEval and PaperBench JudgeEval do (F1 0.91 and 0.83). Meta shows a local-size judge works: its grader is Qwen3-30B-A3B, a frozen copy of the policy.

**Difficulty.** Set it by construction, then calibrate. By construction: how much the seed withholds (Lost in Conversation shards an instruction into pieces; fewer pieces given means harder), how abstract the seed is, and how large the source is. Calibrate on f: run f a few times on an item and take the mean rubric score. Items f passes sometimes but not always are the useful ones (Absolute Zero's learnability reward; "frontier of learnability" curriculum). Items f always passes or always fails teach nothing.

**Contamination.** Use the recency cutoff above. If f searches the web, block the source and pages that cite it (PaperBench, Idea2Plan). Paraphrasing the seed does not hide a source the model has memorised (Yang et al. 2023), so recency and privacy are the real defences.

**Cost on our local model.** Our cost model is input tokens ÷ ~1,460 tok/s plus output and thinking tokens ÷ ~20 tok/s (f3/f4 lessons). A 15k-token source with ~2.5k tokens out costs about 2 minutes for the seed and about 3 minutes for the rubric. Judging one plan level by level is about 4 calls, roughly 2–3 minutes. Calibrating difficulty is the expensive part: one f run took 4,800 s in f4, so 3 runs per item is about 4 hours. Calibration should therefore reuse the f runs an iteration makes anyway. The thinking-token counts here are my assumption. A measured seed-generation call would prove them wrong.

## 1. Reverse generation: inputs from outputs

**Instruction Backtranslation (Humpback).** Li et al., Meta, Aug 2023. https://arxiv.org/abs/2308.06259. A backward model M_yx = p(x|y) is fine-tuned on seed pairs. It writes an instruction for each of 502k ClueWeb segments. The model then scores each pair on a 5-point scale and keeps the high ones (A4: 195,043 pairs at score ≥ 4; A5: 41,821 at ≥ 4.5). Two rounds of this. Key finding: "increasing the quantity of high-quality data provides further gains", while more low-quality data does not. Import: write the seed backward from the source, then score and filter. Cost: two calls per candidate.

**LongForm, reverse instructions.** Köksal et al., Apr 2023. https://arxiv.org/abs/2304.08460. Take human-written documents (C4, Wikipedia), and have an LLM write the instruction each document answers. Import: same as Humpback, without a trained backward model. One call per document.

**Evol-Instruct (WizardLM).** Xu et al., Apr 2023, ICLR 2024. https://arxiv.org/abs/2304.12244. Rewrites instructions "step by step into more complex instructions": add constraints, deepen, concretise, add reasoning steps. Failed rewrites are dropped. Import: a way to make harder variants of one seed, and so a difficulty ladder per source. One call per step.

**Ragas testset generation.** https://docs.ragas.io/en/stable/concepts/test_data_generation/rag/. Builds a knowledge graph of document chunks, then synthesises queries with a reference answer. Each query has a type (single-hop or multi-hop, specific or abstract), a length (short, medium, long), a style and a persona. Import: the explicit knobs for seed length and abstraction. It targets question answering, not plans.

**OSS-Instruct (Magicoder).** Wei et al., Dec 2023, ICML 2024. https://arxiv.org/abs/2312.02120. Generates coding problems from open-source code snippets: 75K instructions. Import: real artefacts as the anchor that keeps synthetic tasks diverse.

**SWE-smith.** Yang et al., Apr 2025. https://arxiv.org/abs/2504.21798. For a Python repo, it synthesises task instances that break existing tests, and writes the task text for them. 50k instances from 128 repos. SWE-agent-LM-32B trained on it reaches 40.2% on SWE-bench Verified.

**R2E-Gym.** Jain et al., Apr 2025. https://arxiv.org/abs/2504.07164. Over 8.7K executable tasks. Its SYNGEN recipe uses "test-generation and back-translation directly from commits", so it needs no human-written issue. This is the closest code analogue of our approach: the commit is the answer, the problem statement is written backward.

**SWE-Gym.** Pan et al., Dec 2024, ICML 2025. https://arxiv.org/abs/2412.21139. 2,438 real task instances with runtime, tests and a natural-language task. Real, not reverse-generated. Shown for contrast.

**Paper to plan.**
- *Idea2Plan.* Oct 2025. https://arxiv.org/abs/2510.24891. Input: a research idea rewritten from the abstract. Reference: a plan o4-mini extracts from the full paper in five sections (introduction, key literature, methods, initial experiments, resources and ethics). 200 test and 30 dev papers from ICML 2025. Eight researchers rated the extracted plans 4.0–4.9 out of 5 per section. Import: the whole recipe. It is the nearest match to f.
- *Training AI Co-Scientists using Rubric Rewards.* Meta, Dec 2025. https://arxiv.org/abs/2512.23707. Dataset: https://huggingface.co/datasets/facebook/research-plan-gen. Llama-4-Maverick reads a full paper (under 15,000 words) and extracts up to three goals, 15 rubric items each, and a reference solution. Claude-4-Sonnet keeps the best 10 items and one sample per paper. 22,513 rows across ML, arXiv and PubMed. Experts rated 84% of rubric items as necessary for a good plan. Import: the extraction and selection steps, and the evidence that a 30B local judge is usable.
- *ResearchBench.* Mar 2025. https://arxiv.org/abs/2503.21248. 1,386 papers from 2024 onward, 12 disciplines. Extracts research question, background survey, inspirations and main hypothesis.
- *IdeaBench.* Oct 2024. https://arxiv.org/abs/2411.02429. Ideas generated from titles and abstracts of papers and their references, ranked by GPT-4o into an "Insight Score".
- *Can LLMs Generate Novel Research Ideas?* Si et al., Sep 2024. https://arxiv.org/abs/2409.04109. Over 100 NLP researchers. LLM ideas judged more novel (p < 0.05), slightly less feasible. Names "failures of LLM self-evaluation" as open. Import: a caution against trusting an unvalidated judge.
- *PaperBench.* OpenAI, Apr 2025. https://arxiv.org/abs/2504.01848. Agents reproduce 20 ICML 2024 papers. See section 2.
- *Paper2Code (PaperCoder).* Apr 2025. https://arxiv.org/abs/2504.17192. Paper → plan → analysis → code. Paper2CodeBench: 90 papers from ICLR, ICML and NeurIPS 2024.

**Spec from code.** No standard benchmark turns a whole repository into a design document. The closest are:
- RTL code to design specification, Nov 2025, https://arxiv.org/abs/2512.00045. Its test of a spec is that an engineer could rebuild equivalent hardware from it.
- CodeSpecBench, Apr 2026, https://arxiv.org/abs/2604.12268. Executable pre- and postconditions. The best model passes 20.2% at repository level.
- PRDBench: 50 Python projects, each with a PRD, criteria and a reference implementation (AAMAS 2026, https://ifaamas.org/Proceedings/aamas2026/pdfs/HJFB4234.pdf).
- DevBench: PRD → design → code → tests (https://hub.baai.ac.cn/view/36151).

Import: a project with a PRD and a repo is a ready-made item. The PRD's goal becomes the seed, and the PRD, design and repo become the proper answer.

## 2. Proper answers for open-ended plans

**PaperBench's rubric tree.** Each paper's rubric is a tree, written with the paper's authors. Leaves are binary pass/fail. Siblings carry manual weights. A parent's score is the weighted mean of its children. There are 8,316 leaves over 20 papers, of three kinds: Code Development, Execution, Result Match. The judge (o3-mini, high effort) scores F1 0.83 on JudgeEval and costs about $66 per paper. Best agent: Claude 3.5 Sonnet (New), 21.0%. ML PhDs reach 41.4% after 48 hours. Import: the tree shape matches f's plan tree. Weighted leaves map to worker tasks, parents to the levels above.

**Idea2Plan's sectioned yes/no rubric.** Five sections of yes/no questions. Section score is the fraction satisfied. Paper score is the mean of the sections. Rules for writing questions: citation questions check for similar work, not one paper; examples are illustrative; each question tests one thing. JudgeEval: 10 plans with human labels. GPT-4.1-mini reaches F1 0.89 at $0.005 per plan, close to o4-mini's 0.91. Import: per-level questions and a small judge check set.

**Meta's rubric grading.** The grader lists weaknesses first. Then, for each rubric item, it lists which of seven general guidelines the plan violates (handles all criteria, specific, no overlooked flaws, justified, cost-efficient, ethical, consistent). An item passes only with no violations. Score = fraction passed. Rubric items avoid "specific outcome numbers that cannot be predicted". Import: general guidelines plus item-specific checks. The guidelines are close to our levels standard.

**Rubrics as Rewards.** Jul 2025. https://arxiv.org/abs/2507.17746. 7–20 items per prompt (7.5 on average), each tagged Essential, Important, Optional or Pitfall. Two ways to aggregate: a weighted sum of binary checks, or one judge call that sees all items and gives a 1–10 score. The single call did best. Rubrics written with reference answers beat rubrics without them.

**DeepResearch Bench (RACE).** Jun 2025. https://arxiv.org/abs/2506.11763. 100 PhD-level tasks. The judge writes task-specific criteria and weights under four fixed dimensions. It scores both the target and a reference report. Final score = S(target) / (S(target) + S(reference)). Reason: scoring alone gives "uniformly high scores". Pairwise agreement with experts 71.3%, above the 68.4% experts reach with each other. Import: when two f versions must be compared, score relative to the reference, not alone.

**Arena-Hard.** Apr/Jun 2024. https://lmsys.org/blog/2024-04-19-arena-hard/, https://arxiv.org/abs/2406.11939. Pairwise against a fixed baseline answer, judged twice with positions swapped, five preference labels. Import: pairwise judging of f's plan against the previous generation's plan on the same seed.

**Paper2Code.** The judge sees the paper and, when it exists, the authors' repo. It lists components, rates severity, critiques, then gives a 1–5 score. Reference-based and reference-free scores correlate at r = 0.79. Rank correlation with humans: 0.78 with the reference, 0.73 without. The reference adds a little, not everything.

**HealthBench.** May 2025. https://arxiv.org/abs/2505.08775. 5,000 conversations, 48,562 rubric criteria, written by 262 physicians. Shows instance-specific rubrics at scale.

**The one-reference pitfall.** Every effort above handles it the same way. It does not compare text with the reference. It derives checks that any valid answer must pass, and keeps out checks that only the reference's particular choices would pass. Idea2Plan says this outright ("common desiderata", "not exact matches"). Meta drops unpredictable specifics. RACE scores against the reference rather than requiring a copy of it. Import: when writing rubric items from a source, drop items that test the source's choice among valid alternatives. Keep items that test what the seed requires.

## 3. Difficulty

**Pass rate and learnability.** Absolute Zero (May 2025, https://arxiv.org/abs/2505.03335): the proposer's reward is 0 when the solver's mean success is 0 or 1. Otherwise it is 1 minus the mean success, estimated by Monte Carlo rollouts. "Learning to Reason at the Frontier of Learnability" (Feb 2025, https://arxiv.org/abs/2502.12272) samples questions "where the agent sometimes succeeds, but not always". DAPO (Mar 2025, https://arxiv.org/abs/2503.14476) drops prompts that are always solved or never solved. Import: difficulty = 1 − f's mean rubric score; prefer items in the middle band.

**Item response theory (IRT).** IRT fits a difficulty per item and an ability per model from a matrix of results. Easy2Hard-Bench (Sep 2024, NeurIPS D&B, https://arxiv.org/abs/2409.18433) labels six datasets with IRT and Glicko-2 from human and LLM results. tinyBenchmarks (Feb 2024, ICML, https://arxiv.org/abs/2402.14992) estimates MMLU with 100 curated items. Fluid Benchmarking (Sep 2025, COLM, https://arxiv.org/abs/2509.11106) picks items adaptively by ability and matches MMLU with fifty times fewer items. Import: IRT needs many solvers per item. Our solvers are f's generations. It becomes usable once several generations have run on the same items.

**Difficulty by what the seed withholds.** Lost in Conversation (May 2025, https://arxiv.org/abs/2505.06120). Each instruction is split into shards. Shard 1 gives the high-level intent and later shards add detail. A GPT-4o-mini user simulator reveals at most one shard per turn. 600 instructions across six tasks. Sharding cost about three hours of manual work per 100 instructions. Models drop 39% on average from full to sharded. Aptitude falls about 16%, unreliability rises about 112%. Giving all shards in one turn ("concat") recovers 95.1%. So the drop comes from the conversation, not from lost information. Import: a seed is shard 1. The simulated user holds the remaining shards and reveals them when asked. Difficulty = how many shards the seed withholds. This fits a simulated user driving f.

**Difficulty by prompt qualities.** Arena-Hard's BenchBuilder scores each prompt 0–7 on seven qualities: specificity, domain knowledge, complexity, problem-solving, creativity, technical accuracy, real-world application. It keeps clusters with mean ≥ 6. Import: a cheap one-call difficulty prior before any f run.

**Seed length and abstraction.** Ragas sets query length and abstraction explicitly. Evol-Instruct makes harder variants step by step. Import: from one source, write a seed at two or three abstraction levels. That gives items of known relative difficulty at the cost of one call each.

## 4. Contamination and leakage

**Recency cutoffs.** LiveCodeBench (Mar 2024, https://arxiv.org/abs/2403.07974) dates each problem and tests only on problems after a model's cutoff. SWE-rebench (May 2025, https://arxiv.org/abs/2505.20411) keeps mining fresh tasks: over 21,000. It finds some models look better on older SWE-bench Verified because of contamination. ResearchBench uses 2024+ papers, with a stricter post-July-2024 subset. Idea2Plan excludes papers with an arXiv version before October 2024.

**Blocking the source at run time.** PaperBench gives each paper a blacklist (the authors' code, other replications). A monitor found 10 violations in 646 runs, scored 0. Idea2Plan blocks the target paper, papers citing it and anything after Jan 30, 2025. Import: if f's research step searches, pass the item's blocklist with the seed.

**Paraphrase does not help.** Yang et al. (Nov 2023, https://arxiv.org/abs/2311.04850): rephrased test items bypass n-gram decontamination. A 13B model trained on rephrased items reaches GPT-4-level scores on MMLU, GSM8K and HumanEval. Import: a reverse-written seed does not hide a source the model knows.

**Detection.** Min-K% Prob (Oct 2023, https://arxiv.org/abs/2310.16789) flags text a model has seen from its lowest-probability tokens. It needs per-token probabilities. I am not sure our local serving path returns them.

**Canaries.** BIG-bench puts a canary string in every task file "to prevent benchmark tasks from leaking into web-scraped training data". Needed only if the items are published.

**Private sources.** Our own design documents and past plans have never been on the web. They are the cleanest sources available.

## 5. Format, size and tooling

**Sizes.** Evaluation sets are small. PaperBench has 20 papers. PRDBench has 50 projects. DeepResearch Bench has 100 tasks. Idea2Plan has 200 test and 30 dev. Arena-Hard has 500 prompts. Lost in Conversation has 600 instructions. Training sets are larger: Meta 22,513; SWE-smith 50k; Humpback 502k candidates.

**Formats.**
- Meta's rows have Goal, Rubric (a list of strings), Reference solution, article_id, q_id, Subdomain, Category. Licence CC-BY-NC.
- Idea2Plan: the rubric is a JSON object of five sections. Judge output is JSON with Yes/No and an explanation per question.
- PaperBench: a JSON rubric tree per paper, with weights and leaf types, in https://github.com/openai/preparedness.
- SWE-bench family: JSONL with instance_id, problem_statement, patch and tests.

Import: `items/<id>.json` holds the seed, the shards it withholds, the source reference and date, the rubric (items tagged by level, with weights), the blocklist, the difficulty by construction, and the measured difficulty with the f versions that measured it.

**Tooling.** Ragas (testset generation from documents). Lost in Conversation's code: https://github.com/microsoft/lost_in_conversation. PaperBench's judge and rubric code is in openai/preparedness. Meta's dataset is on Hugging Face. None of these is needed to start. The recipe is a few prompts: seed, rubric, select, judge.

## Sources

- Humpback, instruction backtranslation: https://arxiv.org/abs/2308.06259
- LongForm, reverse instructions: https://arxiv.org/abs/2304.08460
- Evol-Instruct / WizardLM: https://arxiv.org/abs/2304.12244
- Ragas test data generation: https://docs.ragas.io/en/stable/concepts/test_data_generation/rag/
- Magicoder / OSS-Instruct: https://arxiv.org/abs/2312.02120
- SWE-smith: https://arxiv.org/abs/2504.21798
- R2E-Gym: https://arxiv.org/abs/2504.07164
- SWE-Gym: https://arxiv.org/abs/2412.21139
- SWE-rebench: https://arxiv.org/abs/2505.20411
- Idea2Plan: https://arxiv.org/abs/2510.24891
- Training AI Co-Scientists using Rubric Rewards: https://arxiv.org/abs/2512.23707
- facebook/research-plan-gen dataset: https://huggingface.co/datasets/facebook/research-plan-gen
- ResearchBench: https://arxiv.org/abs/2503.21248
- IdeaBench: https://arxiv.org/abs/2411.02429
- Can LLMs Generate Novel Research Ideas?: https://arxiv.org/abs/2409.04109
- PaperBench: https://arxiv.org/abs/2504.01848
- Paper2Code: https://arxiv.org/abs/2504.17192
- RTL design specifications from code: https://arxiv.org/abs/2512.00045
- CodeSpecBench: https://arxiv.org/abs/2604.12268
- PRDBench (AAMAS 2026): https://ifaamas.org/Proceedings/aamas2026/pdfs/HJFB4234.pdf
- ProjectEval: https://arxiv.org/abs/2503.07010
- DevBench write-up: https://hub.baai.ac.cn/view/36151
- Rubrics as Rewards: https://arxiv.org/abs/2507.17746
- DeepResearch Bench: https://arxiv.org/abs/2506.11763
- Arena-Hard blog: https://lmsys.org/blog/2024-04-19-arena-hard/
- Arena-Hard / BenchBuilder paper: https://arxiv.org/abs/2406.11939
- HealthBench: https://arxiv.org/abs/2505.08775
- Absolute Zero: https://arxiv.org/abs/2505.03335
- Learning to Reason at the Frontier of Learnability: https://arxiv.org/abs/2502.12272
- DAPO: https://arxiv.org/abs/2503.14476
- Easy2Hard-Bench: https://arxiv.org/abs/2409.18433
- tinyBenchmarks: https://arxiv.org/abs/2402.14992
- Fluid Benchmarking: https://arxiv.org/abs/2509.11106
- LLMs Get Lost in Multi-Turn Conversation: https://arxiv.org/abs/2505.06120
- LiveCodeBench: https://arxiv.org/abs/2403.07974
- Rephrased samples and contamination: https://arxiv.org/abs/2311.04850
- Min-K% Prob: https://arxiv.org/abs/2310.16789
- BIG-bench canary: https://github.com/google/BIG-bench
- Local cost model: prototype2/f4/LESSONS_FROM_F3.md, ~/shared/survey/survey-f5-speed-context-guardrails.md
