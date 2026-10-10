# Survey for f5: user surrogate, plan critique, self-improvement, plan presentation

## Answer first

Four things are worth importing now. Each is cheap on a local model.

1. **Surrogate: keep the prompt-based simulated Director, and add a learned preference text from the Director's edits (PRELUDE/CIPHER).** Gate pre-filled answers with a confidence threshold that is calibrated on held-out past rounds. Ask the person only the items with the highest uncertainty. No fine-tuning is needed.
2. **Critique: compare two at a time, with a rubric (levels.txt).** Run each pair in both orders. Turn the many cheap judge verdicts plus a few human labels into an honest quality number with prediction-powered inference (PPI, explained in section 2).
3. **Self-improvement: GEPA for f's prompts first; an archive-based code loop (ShinkaEvolve style, which needs few samples) later.** GEPA reads traces and the Director's text complaints, which is exactly what f5 produces. For seed generation at the right difficulty, use the "learnable" reward from Absolute Zero: keep seeds that f solves sometimes, not always and not never.
4. **Presentation: tables and mind maps cut reading time (about 43% and 32% in one user study) with no loss of accuracy.** The page already uses markmap. Add Mermaid for small diagrams inside a node, and keep the tree as the source of truth that both views render.

Speed is the top priority. The fastest ideas are the ones that add zero model calls on the critical path: confidence gating, calibration tables, and rendering. The slowest are evolutionary code search and RL. Run those offline, between Director sessions, never inside a round.

## 1. A strong user surrogate

**PRELUDE / CIPHER: learn a person's preference as text from their edits** (Gao et al., NeurIPS 2024, Microsoft Research).
- What it is. The agent watches how a user edits its output. An LLM infers a short preference description from each edit. For a new item it retrieves the preferences from the k most similar past contexts and merges them into the prompt.
- Why it fits. The Director's dataset already holds edits and answers. The learned preference is readable text, so the Director can check and correct it. That matches the labeller role in f5.
- What we would import. The method, not code: an "inferred preferences" block per context, retrieved by similarity, added to the simulated Director's message.
- Cost. At most three extra LLM calls per round in the paper; we can cache the inferred preference per past round, so the online cost is one retrieval and no extra call. No training.

**UserLM-8b: a model trained to play the user, not the assistant** (Microsoft Research, Oct 2025, MIT licence, GGUF builds exist).
- What it is. Llama-3.1-8B trained on WildChat to produce user turns from a "task intent", including when to end the conversation. It matches real user behaviour better than an assistant model prompted to act as a user.
- Why it fits. f5's simulated user must write seed texts and complaints that sound like a person, not like an assistant. Assistant models make polite, over-complete users.
- What we would import. The model, as a candidate for the seed writer and complainer role. The Director-specific knowledge still comes from the dataset in the prompt.
- Cost. 8B runs fast locally. It is weaker at reasoning, so it should write and complain, not judge.

**tau2-bench user simulator** (Sierra Research, active in 2026; now also grown into a "tau3" with banking and voice domains).
- What it is. The reference setup for testing agents against a simulated user: an orchestrator passes messages between agent, user simulator and environment. The user follows an instruction and stops when the goal is met.
- What we would import. The structure: the user simulator has its own instruction, its own tools, and a stop signal; the run is scored automatically. Its known weakness is useful too: its user can never walk away or refuse the goal (see the "decision fidelity" paper). Our simulated Director should be allowed to say "this plan is not worth reading".
- Cost. Structure only. No runtime cost.

**Twin-2K-500 and the digital-twin studies** (Toubia et al., Columbia, 2025, Marketing Science).
- What it is. 2,058 people answering 500+ questions, used to test whether an LLM can predict one person's answer from their earlier answers.
- Lesson. Twins capture how people differ from each other, but miss precise individual answers. Richer persona text pushes answers toward a typical ("blue-shifted") person. So: give the surrogate the person's actual past rounds, not a long description of the person. This is what f4 already does.
- Cost. None. It is evidence, not a component.

**Confidence for pre-filled answers.**
- Conformal abstention (Abbasi-Yadkori et al. 2024 and 2025–26 follow-ups). Sample the surrogate a few times, measure agreement, and set the "answer for the person" threshold on held-out past rounds so the error rate stays under a chosen level. The guarantee holds only if the rounds are alike; the Director's taste drifts, so recalibrate on the newest rounds.
- A simpler version that needs no sampling: keep a reliability table. Bucket the surrogate's stated confidence, count how often each bucket matched the Director, and use the measured rate, not the stated one. This costs nothing at run time.
- Cost. Self-consistency costs k calls per item; on a local model run them in parallel, k = 3 is usually enough. The reliability table is free.

**Choosing what to ask the human (active learning).**
- MAPLE (AAAI 2025). Pick the question whose answer most reduces uncertainty about the person's preference, and favour questions that are easy to answer.
- A 2026 workshop result warns that, for training on preference pairs, uncertainty-based picking often does not beat random picking. So measure against random before trusting it.
- What we would import. The rule "ask where the surrogate is least sure and the item matters most". f4's attention score is already this; add "surrogate uncertainty" as a factor.
- Cost. Free if the uncertainty comes from the reliability table.

**Few-label personal reward models** (PAL, ICLR 2025; LoRe, Meta 2025; Meta Reward Modeling, 2026).
- What it is. A shared set of base reward functions; a new user is a small weight vector learned from a few labels.
- Fit. Useful only when there are many users. With one Director, a prompt with his past rounds does the same job. Keep for later.
- Cost. Needs a reward model and training. Not now.

**Survey to read once.** Ni et al., "A Survey on LLM-based Conversational User Simulation", EACL 2026.

## 2. Critique and judging plans

**Pairwise with a rubric, both orders.**
- Evidence. Pairwise verdicts track humans better than 1–10 scores. Absolute scores bunch together; RewardBench 2 notes that generative judges give the same rating to several candidates. Position bias exists in every format. Rubric-based pointwise scoring also has position bias over the score options (2026); balanced permutation fixes it.
- What we would import. Judge two nodes (or two versions of one node) against levels.txt. Run A-B and B-A. Count a win only if both orders agree; otherwise call it a tie. Feed wins into the Elo rating f4 already has.
- Cost. Two calls per pair. Cheap on a local model if the prompt prefix (rubric + board) is shared and cached by the server.

**Prometheus 2 and its successors** (prometheus-eval, open 7B and 8x7B judges).
- What it is. An open judge trained to score against a user-written rubric, in both absolute and pairwise modes.
- Fit. A 7B judge that follows a rubric well is fast. Its training data predate the newest models, so first check it against the Director's labels on 50 items.
- Cost. 7B locally: fast. Use it as the first-pass critic; send disagreements to the large model.

**EvalGen and "criteria drift"** (Shankar et al., UIST 2024).
- What it is. People cannot fully write criteria before grading; grading changes the criteria. EvalGen proposes candidate checks (code or LLM prompts), asks the person to grade a few outputs, and keeps the checks that agree with the grades.
- Fit. This is the f5 labeller loop. The levels.txt standard will change as the Director approves and rejects. Treat the rubric as versioned and re-select critic prompts against the latest labels.
- Cost. A few human grades per change. Checks written as code cost nothing at run time; prefer them where a rule is mechanical (for example "a split node has an overview").

**Prediction-powered inference (PPI): honest numbers from a biased judge plus a few human labels.**
- What it is. The judge labels many items; the human labels a small random subset; PPI corrects the judge's bias using that subset. The estimate is unbiased whatever the judge's errors; a worse judge only widens the error bar. Code: github.com/yiqunchen/debias-llm-as-a-judge (ICML 2026).
- Fit. f5 needs to know if a change to f really improved it. PPI turns, say, 30 approved labels plus 1,000 judge verdicts into a win rate with an error bar.
- Cost. Arithmetic only.

**Rubric quality.** RubricBench (2026) reports a 27-point accuracy gap between human-written and model-written rubrics. Keep levels.txt human-approved; let models propose edits, not own it.

## 3. Self-improving loops

**GEPA: reflective prompt evolution** (gepa-ai/gepa, MIT, about 4.7k stars by May 2026; also in DSPy as dspy.GEPA; ICLR 2026 oral).
- What it is. It runs the program, reads the full trace and any text feedback, asks an LLM to rewrite a prompt, and keeps a Pareto set of prompts that each win on some examples. Reported: better than MIPROv2 and than RL (GRPO) with up to 35x fewer rollouts.
- Fit. Best match for f5. f's behaviour lives in prompts (director.txt, levels.txt, the expander's prompt). The Director's complaints are text feedback. The standalone package has an adapter interface, so f can stay TypeScript and call GEPA as an offline Python sidecar over saved runs.
- What we would import. The package, or just its loop: trace + feedback -> reflection -> candidate prompt -> score on a held-out set of past rounds -> Pareto keep.
- Cost. Tens to a few hundred program runs per optimisation. Run it between sessions on replayed rounds, never during a round.

**DSPy** (stanfordnlp/dspy, about 34–38k stars, release 3.3.1 in Aug 2026).
- Fit. Only if we want typed signatures and its other optimisers. It is Python and wants to own the program. For f, import GEPA alone.

**ShinkaEvolve** (Sakana AI, Apache 2.0, ICLR 2026) and **OpenEvolve** (open AlphaEvolve, Apache 2.0, about 5k stars).
- What it is. Evolve code files: sample a parent from an archive, have an LLM edit it, score it, keep it if good or new. ShinkaEvolve reaches results with about 150 samples where others need thousands, through better parent choice, rejecting near-duplicate code before scoring, and a bandit that picks which LLM to use.
- Fit. For evolving f's code (the scheduler, the rater) against a fast automatic score. ShinkaEvolve's sample efficiency matters most for us because each f run is slow.
- Cost. Every candidate needs a full scoring run. Use replayed rounds and the simulated Director as the scorer so one evaluation takes minutes, not a session.

**Darwin Gödel Machine and Huxley-Gödel Machine** (DGM: Sakana/UBC, ICLR 2026, about 2.2k stars; HGM: KAUST, ICLR 2026 oral, code at metauto-ai/HGM).
- What it is. A coding agent edits its own code; variants live in an archive; benchmarks decide what stays. HGM adds one lesson: pick which variant to improve next by how well its descendants did, not by its own score. It gets better results with fewer CPU hours.
- Fit. The pattern for "f improves itself". HGM's selection rule is a cheap change worth copying into any archive loop.
- Cost. Very high in the papers (SWE-bench runs). For us, only viable with a small, fast scorer.

**SICA, A Self-Improving Coding Agent** (Robeyns et al., 2025, MIT). One agent edits itself, no separate meta-agent. Repo appears inactive. Read for the design, do not import.

**ADAS / Meta Agent Search** (ICLR 2025) and **TextGrad** (Nature, March 2025). Earlier members of the same family. GEPA supersedes them for prompt work.

**Generating seeds at the right difficulty.**
- Absolute Zero (2025). A proposer writes tasks and a solver attempts them. The proposer is rewarded only when the solver's success rate is between 0 and 1: reward = 1 − success rate, and 0 if always or never solved.
- Self-Challenging Agents (Meta/Berkeley, NeurIPS 2025). Each generated task comes with a check, a working solution, and failing cases; tasks whose checks do not separate them are dropped.
- What we would import. For the simulated user writing seeds: score each seed by how often f, run a few times, produces a plan the simulated Director accepts. Keep seeds in the middle band. Attach to each seed the complaint the simulated Director would raise, as its check.
- Cost. Several f runs per seed. Batch seed scoring offline; use a short f run (two rounds) as the probe.

**Human at minimal cost.** Combine three items above. The human approves only (a) items where the surrogate is unsure, (b) a small random sample for PPI, and (c) proposed changes to the rubric. Everything else is judged by the surrogate.

## 4. Showing plans in more than prose

**Evidence that structure helps.** StructSum (2024) found that tables cut reading time by 42.9% and mind maps by 31.9% compared with plain text, with no loss in accuracy. LLMs do not produce good tables and mind maps by default; a critique step raised quality by 15 points for tables and 37 for mind maps. So add a structure check to the critic. I did not find a 2025 human study on LLM-written plan diagrams.

**Which diagram language for an LLM to write.**
- Mermaid is the safest. Models write it most reliably, it renders in the browser, and it has flowchart, sequence, state, Gantt and mindmap types. MermaidSeqBench (NeurIPS 2025 workshop) shows syntax errors still happen, so validate by parsing before showing and send parse errors back to the model.
- D2 has cleaner syntax and better layout but no small browser renderer; it needs a WASM build or a server. Graphviz suits dense graphs; viz.js renders it in the browser.
- Cost. A Mermaid parse is milliseconds. One retry on a parse error costs one model call.

**Rendering libraries for the page.**
- markmap (already in f4's page): Markdown outline to interactive mind map, with fold and zoom.
- mermaid.js: diagrams inside a node's text.
- elkjs: layered layout for trees and graphs, if we leave markmap's layout. Pair with React Flow or plain SVG.
- Tables are plain HTML from Markdown; no library needed.

**How spec tools present plans.**
- Kiro (AWS): three gated files per feature, requirements in EARS form ("When X, the system shall Y"), then design, then tasks, with links from tasks back to requirements.
- GitHub Spec Kit (about 115k stars by June 2026): a constitution file of fixed principles, then specify, plan, tasks commands. Known for being verbose.
- OpenSpec (Fission AI): light Markdown specs, optional Given/When/Then, and change proposals written as ADDED / MODIFIED / REMOVED deltas.
- What we would import. f's levels already match this ladder: root = proposal, depth 1 = contract with checkable scenarios (Kiro's EARS, OpenSpec's Given/When/Then), depth 2 = design, depth 3+ = tasks. Two ideas are new for us. First, show a revision as a delta (added, changed, removed), so the Director reads only the change. Second, show depth-1 scenarios as a table of "when / then" rows.

## Sources

- PRELUDE/CIPHER: https://www.microsoft.com/en-us/research/publication/aligning-llm-agents-by-learning-latent-preference-from-user-edits/
- UserLM-8b: https://huggingface.co/microsoft/UserLM-8b (paper arXiv 2510.06552)
- tau2-bench: https://github.com/sierra-research/tau2-bench
- Decision fidelity of user simulators: https://arxiv.org/pdf/2606.20708
- Survey on LLM-based conversational user simulation: https://aclanthology.org/2026.eacl-long.200
- Twin-2K-500: https://arxiv.org/abs/2505.17479
- Conformal abstention: https://arxiv.org/html/2405.01563v1 ; https://www.arxiv.org/abs/2502.06884
- MAPLE active preference learning: https://arxiv.org/abs/2412.07207v2
- PAL: https://proceedings.iclr.cc/paper_files/paper/2025/hash/2858f8c8683aaa8c12d487354cf328dc-Abstract-Conference.html
- LoRe: https://arxiv.org/abs/2504.14439
- Meta Reward Modeling: https://arxiv.org/html/2601.18731v1
- CalibraEval (ACL 2025): https://preview.aclanthology.org/landing_page/2025.acl-long.808.pdf
- Position bias in rubric judges: https://arxiv.org/html/2602.02219v1
- Judging the judges, position bias: https://arxiv.org/html/2406.07791v6
- Prometheus 2: https://arxiv.org/abs/2405.01535v2 ; https://github.com/prometheus-eval/prometheus-eval
- RewardBench 2: https://arxiv.org/pdf/2506.01937
- RubricBench: https://arxiv.org/html/2603.01562v1
- EvalGen / criteria drift: https://arxiv.org/pdf/2404.12272
- PPI for noisy LLM judges: https://arxiv.org/html/2601.05420v1 ; https://github.com/yiqunchen/debias-llm-as-a-judge
- GEPA: https://arxiv.org/abs/2507.19457 ; https://github.com/gepa-ai/gepa ; https://dspy.ai/api/optimizers/GEPA/overview/
- DSPy: https://github.com/stanfordnlp/dspy ; https://www.promptquorum.com/power-local-llm/dspy-review
- ShinkaEvolve: https://sakana.ai/shinka-evolve/ ; https://arxiv.org/pdf/2509.19349
- OpenEvolve: https://pypi.org/p/openevolve ; https://www.sourcepulse.org/projects/2626950
- Darwin Gödel Machine: https://arxiv.org/abs/2505.22954v2 ; https://github.com/jennyzzt/dgm
- Huxley-Gödel Machine: https://arxiv.org/abs/2510.21614v2
- SICA: https://arxiv.org/abs/2504.15228v2
- ADAS: https://github.com/ShengranHu/ADAS
- TextGrad: https://github.com/zou-group/textgrad
- Absolute Zero: https://arxiv.org/pdf/2505.03335
- Self-Challenging Agents: https://arxiv.org/html/2506.01716v1
- StructSum (tables and mind maps vs text): https://arxiv.org/abs/2401.06837v1
- MermaidSeqBench: https://arxiv.org/abs/2511.14967
- markmap: https://markmap.js.org/api/modules/markmap_lib.html
- elkjs: https://github.com/kieler/elkjs/releases
- Spec tools compared (Kiro, Spec Kit, OpenSpec): https://levelop.dev/blog/spec-driven-development-tools-compared ; https://codemyspec.com/blog/kiro-vs-openspec ; https://ssojet.com/blog/best-spec-driven-development-tools
