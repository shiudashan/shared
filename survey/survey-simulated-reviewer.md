# Survey: a simulated reviewer for one person

This goes deeper than `~/shared/survey/survey-simulated-user.md` and
`~/shared/survey/survey-f5-surrogate-selfimprove-multimodal.md` on three questions. How to collect and
choose one person's examples. How to train a simulator of one person. How systems review on
someone's behalf. It does not repeat entries already covered there, except to add numbers.

Numbers were checked against the paper's abstract or full text unless marked "unverified".

## Answer first: a recommended path

Keep the model frozen until the person has hundreds of labelled items. Put the person's examples
in the prompt, then add readable rules distilled from them. Optimise the prompt offline. Only
then consider a LoRA (a small trainable add-on to a frozen model), on a smaller judge. Measure every step
against the person's own consistency.

The evidence for this order:
- Prompt-side methods report gains from 2 to 50 labels (MemAlign, SynthesizeMe, GEPA).
- A per-person LoRA has won only with 55 to 960 items per person (OPPU).
- On the one direct test of individual prediction, fine-tuning did not beat a plain persona prompt
  (Twin-2K-500: 69.6% against 71.7%).
- Methods that adapt to a new person from 4 to 50 labels (LoRe, PAL, VPL, FSPO, MRM) all need a base
  trained on many other people first. We have one person, so they do not apply.

The steps, each named with its source:

0. **Measure first: agreement divided by the person's own consistency (Park et al. 2024;
   Twin-2K-500; Judging the Judges).** Hold out items. Score the simulator with Cohen's kappa
   (agreement corrected for chance), not percent agreement. Re-ask the person 20 to 30 old items
   blind, weeks later, to get the ceiling. Published simulators of individuals reach 85% to 88% of
   the person's own retest agreement. Expect a ceiling there.

1. **A few dozen items: show them all, as data, with the person's reasons (Bertsch et al. 2025;
   Mem0; Lampinen et al. 2022; MemAlign).**
   - When the bank fits in context, putting all of it in beats memory systems on accuracy (Mem0:
     full context 72.9 against 66.9 to 68.4).
   - Do not sort examples by label. That cost 25.7 points in Bertsch et al.
   - Ask the person for a short reason with each verdict, not a bare label. Explanations help large
     models in context (Lampinen). At 5 examples or fewer, MemAlign found free-text feedback beats
     labels.
   - Keep rejected items, marked as rejected.

2. **Same stage: decide only when sure, and send the rest to the person (Trust or Escalate,
   ICLR 2025; AutoCommenter; CHiL(L)Grader).**
   - Confidence comes from disagreement. Run the simulator several times with different example
     subsets ("Simulated Annotators", K and N up to 5). Agreement across runs is the confidence.
   - Set the threshold on held-out items. The paper's guarantee used 392 to 500 calibration items.
     Below that, use a reliability table: per confidence bucket, the measured agreement.
   - Production reviewers (Google AutoCommenter) start with very high precision and stay silent
     below the threshold. Their lesson: "Even a few negative user experiences can erode trust."

3. **30 to 100 items: distil readable rules, kept beside the examples (MemAlign; SynthesizeMe;
   PROSE; AutoLibra).**
   - MemAlign keeps two stores. "Semantic memory" holds principles distilled from the person's
     feedback. "Episodic memory" holds hard cases, retrieved per input (k=5). Gains appear after 2
     to 10 examples. Cost about 40 s per alignment.
   - SynthesizeMe and PROSE keep a rule only if it raises held-out accuracy or holds across several
     of the person's items.
   - AutoLibra clusters free-text critiques of agent runs into named fault kinds, each with a
     definition and examples. Its coverage check says which feedback the kinds do not explain.

4. **Which items to ask the person for next: coverage and disagreement, not uncertainty alone
   ("Random Is Hard to Beat" 2026; Margatina et al. 2023; vote-k; GATE).**
   - For preference data, uncertainty-based selection mostly did not beat random with modern
     models.
   - Diversity selection (vote-k) beat random by 11% to 13% at 18 to 100 labels.
   - Items the simulator escalates (step 2) are the natural queue. Add a few random items so the
     agreement number stays honest.
   - For new fault kinds, have the model ask the person yes/no edge-case questions (GATE). That beat
     both writing the rules by hand and labelling random items, at equal person time.

5. **50 to 300 items: optimise the prompt offline on the person's labels (GEPA; MIPROv2; Fermi).**
   GEPA beat GRPO (an RL fine-tuning method) on Qwen3-8B by 6 points on average, with up to 35x
   fewer rollouts. Fermi optimised one prompt per person from about 20 past opinions and beat
   retrieved examples by 5 to 14 points. Split train and held-out by time.

6. **Hundreds of items, and only if steps 1 to 5 plateau below the ceiling: a LoRA on a smaller
   judge, with replay (OPPU; CHiL(L)Grader; LLM-Rubric).**
   - CHiL(L)Grader fine-tunes a 7B grader on the teacher's corrections, with old examples replayed.
     It ran on 2 workstation GPUs in about 90 minutes. Without replay, agreement collapsed.
   - LLM-Rubric is cheaper still: a frozen LLM answers rubric questions, and a tiny per-rater
     calibration network maps its answers to that rater's scores.
   - On our hardware: Unsloth reports 4-bit LoRA does not work for MoE models today. A bf16 LoRA of
     Qwen3-30B-A3B takes about 63 to 86 GB. An 80B MoE needs a 192 GB-class GPU.

7. **Throughout: keep the bank current (EvalGen; NS-DPO; PersonaMem).** Criteria change while a
   person grades. Models recall a changed preference better than they apply it (60% to 70% against
   30% to 50%). So retire superseded items explicitly, weight recent items more, and recalibrate
   the threshold on the newest items.

## 1. Collecting and choosing one person's examples

### Which examples to ask for

**"Random Is Hard to Beat: Active Selection in Online DPO with Modern LLMs"** (Oh et al., April
2026). https://arxiv.org/abs/2604.02766
- Finding, quoted: "active preference learning offers little to no benefit over random sampling
  for online DPO with modern LLMs."
- Setup: four small models, HH-RLHF and UltraFeedback, entropy-based selection. Random usually won
  (for example 0.547 against 0.490 with a GPT-5 judge). There were some reversals.
- Active selection cost about 20x per cycle.
- Earlier precedent: Gleave and Irving 2022 (https://arxiv.org/abs/2203.07472), "ensemble active
  learning does not outperform random sampling."
- Import: always keep a random slice in what the person labels.

**Margatina et al., "Active Learning Principles for In-Context Learning with LLMs"** (Findings of
EMNLP 2023). https://arxiv.org/abs/2305.14264
- Compared uncertainty, diversity, similarity and random selection of demonstrations to label, on
  24 tasks.
- Similarity-based selection beat all others. Uncertainty sampling did poorly.
- Data: an unlabelled pool. Compute: embeddings only.

**vote-k, "Selective Annotation Makes Language Models Better Few-Shot Learners"** (Su et al.,
ICLR 2023). https://arxiv.org/abs/2209.01975 ; https://github.com/HKUNLP/icl-selective-annotation
- Method, quoted: "an unsupervised, graph-based selective annotation method, vote-k, to select
  diverse, representative examples to annotate." It builds a nearest-neighbour graph and discounts
  items near ones already chosen.
- 12.9% and 11.4% relative gain over random at budgets of 18 and 100 labels.
- Import as-is for choosing which past runs or plans to ask the person about. Embeddings only.

**Active sampling for an LLM judge's prompt** (Zhen et al., ACL 2025 Industry).
https://aclanthology.org/2025.acl-industry.67/
- Starts from zero labels. Picks "a small, diverse, informative" set by "a convex optimization
  problem that balances uncertainty and diversity." The labels refine the judge prompt.
- The closest paper to our case. The exact numbers are unverified; I could not open the PDF.

**EvalGen, "Who Validates the Validators?"** (Shankar et al., UIST 2024).
https://arxiv.org/abs/2404.12272
- The user grades outputs. A sampler picks the next output to show from each candidate check's
  pass rate. Checks that agree with the grades are kept.
- With 16 graded outputs: 66.5% alignment with 4 checks, against 54.4% with 9 for a baseline.
- Users in the study graded 5 to 10 outputs.

**AutoLibra** (Zhu et al., ICLR 2026). https://arxiv.org/abs/2505.02820
- New detail beyond the earlier survey: 100 annotated trajectories per domain built the metrics.
  As an optimisation signal, 18 annotated trajectories per stage over 3 stages gave more than 20%
  gain in a text game.
- Import: the coverage check, to see which fault kinds our bank lacks.

### How to elicit cheaply

**Park et al., "Generative Agent Simulations of 1,000 People"** (November 2024; later versions
retitled "LLM Agents Grounded in Self-Reports Enable General-Purpose Simulation of Individuals").
https://arxiv.org/abs/2411.10109
- Protocol: 1,052 people. A 2-hour voice interview run by an AI interviewer, following the American
  Voices Project schedule. Each module has a word budget; follow-ups stop when it runs out.
  Transcripts average 6,491 words. The whole transcript goes in the prompt, with "expert
  reflections".
- First version, normalised by the person's own two-week retest: General Social Survey 0.85 with
  the interview, 0.71 with demographics, 0.70 with a persona paragraph.
- Ablation, quoted: "we randomly removed 80% of the interview transcript (equivalent to removing 96
  minutes of the 120-minute interview) and found that the interview-based agents still achieved an
  average normalized accuracy of 0.79."
- The current version reports interview 83%, survey 82%, both 86%: "Gains over either source alone
  were modest."
- Import: a short structured interview of the person is worth doing once. About 25 minutes gets
  most of the value. The interview gives coverage; the labelled items give precision.

**GATE, "Eliciting Human Preferences with Language Models"** (Li, Tamkin, Goodman, Andreas;
ICLR 2025). https://arxiv.org/abs/2310.11589
- Method, quoted: "models elicit and infer intended behavior through free-form, language-based
  interaction with users." Variants ask open questions, yes/no questions, or show generated edge
  cases.
- 388 people, 5 minutes each. Yes/no questions beat user-written prompts in every setting. Open
  questions beat labelling random examples and pool-based active learning on one task.
- Users found answering questions less effort than writing prompts. Users who wrote their own
  rules sometimes did worse, because they did not know their own preferences.
- Import: the yes/no edge-case question, generated by the model, answered by the person.

**OPEN, "Bayesian Preference Elicitation with Language Models"** (Handa et al., March 2024).
https://arxiv.org/abs/2403.05534. A Bayesian design picks the most informative question and the
model words it naturally. It beat either part alone in a user study. Numbers not extracted.

**Cold-start Bayesian questioning (Pep/CAPE)** (ICML 2026). https://arxiv.org/abs/2602.15012.
80.8% alignment against 68.5% for an RL-trained asker, with 3x to 5x fewer questions. It needs
complete profiles from other people for its prior. Not usable with one person.

**Labels, critiques, pairs, reasons.** I found no 2025–26 study that compares these head to head
for one person. The nearest evidence:
- Lampinen et al. 2022 (https://arxiv.org/abs/2204.02329): explanations help large models in
  context; choosing examples and explanations together beats choosing examples alone.
- MemAlign (section 2): at 5 examples or fewer, free-text feedback beats labels.
- Kreutzer et al. 2018 (https://aclanthology.org/P18-1165/): pairwise and 5-point ratings had
  comparable rater reliability in translation.

### How many examples for what fidelity

**Agarwal et al., "Many-Shot In-Context Learning"** (NeurIPS 2024). https://arxiv.org/abs/2404.11018
- Method, quoted: "Reinforced ICL uses model-generated chain-of-thought rationales in place of
  human examples… Unsupervised ICL removes rationales from the prompt altogether."
- Plain ICL on MATH500 peaked at about 125 shots, then fell. Reinforced ICL plateaued at about 25
  shots, about 5 points higher.
- Repeating 25 examples to fill 1,000 shots lagged 1,000 distinct examples. New information drives
  the gain.
- Order mattered: the best order for one subarea was weak for another.
- Import: Reinforced ICL fits us. Keep only the model's reasoning that reaches the person's verdict
  (the same filter as SynthesizeMe).

**Bertsch et al., "In-Context Learning with Long-Context Models"** (NAACL 2025).
https://arxiv.org/abs/2405.00200
- Quoted: "finetuning is more data hungry than ICL but can exceed long-context ICL performance with
  additional data." And: "example retrieval shows excellent performance at low context lengths but
  has diminished gains with more demonstrations."
- The retrieval advantage fell from 51.5 points at 1 shot to 4.9 points at 1,500 shots.
- LoRA never beat long-context ICL on most datasets. Full fine-tuning needed several thousand
  examples to win.
- Sorting examples by label cost 25.7 points.

**"Can Many-Shot ICL Help Long-Context LLM Judges?"** (COLING 2025). https://arxiv.org/abs/2406.11629
- Zero-shot judging had "nearly half of the ratings being disagreement" across runs.
- Agreement rose with shots and stopped improving at 64 to 128.
- Pairwise judges favoured label "A". Swapping labels helped.

**Zhao et al., "Is In-Context Learning Sufficient for Instruction Following?"** (ICLR 2025).
https://arxiv.org/abs/2405.19874. Many-shot ICL helped "only when using high-quality examples," and
"performance plateaus after 10-30 in-context examples."

**Ceilings for simulating individuals.**
- Twin-2K-500 (https://arxiv.org/abs/2505.17479; Marketing Science 2025): 2,058 people, about 500
  questions each. Full persona 71.7%, human retest 81.7%, random 59.2%. That is 87.7% of retest.
  A summary of the persona: 68.0%. Fine-tuning on 500 personas: 69.6%.
- "Digital Twins as Funhouse Mirrors" (https://arxiv.org/abs/2509.19088, v5 April 2026): 19
  pre-registered studies. Individual accuracy 0.748, against retest 0.817. Average correlation with
  each person's answers only about 0.20. Twins were "only modestly more accurate" than the base
  model. They capture differences between people, not exact answers.
- Kinzinger and Hartmann, German SOEP panel (https://arxiv.org/abs/2606.04592, June 2026): 500
  people. Gains flatten past three quarters of the available history. Raw history beat a narrative
  summary in every cell.
- Lesson: report agreement on the items where the person's verdict differs from a generic
  reviewer's. High overall accuracy can come from easy items.

**Per-rater prediction from the rater's own examples (LeWiDi 2025).**
https://arxiv.org/abs/2509.09524 ; https://arxiv.org/abs/2510.07105. With k=10 of the rater's
examples, similarity sampling against label-balanced sampling made "relatively subtle"
differences. The rater's own examples in context were "crucial."

### Keeping examples current

**Criteria drift (EvalGen, above).** Quoted: "users need criteria to grade outputs, but grading
outputs helps users define criteria." Criteria change in definition and in membership while
grading.

**NS-DPO, "Right Now, Wrong Then"** (ICML 2025). https://arxiv.org/abs/2407.18676. One discount
parameter weights recent data exponentially more. About 10 points better under gradual drift, no
loss without drift. Adding a timestamp to the prompt did not help. Import: the weighting rule,
applied to which items are drawn and how they count in calibration.

**PersonaMem, "Know Me, Respond to Me"** (COLM 2025). https://arxiv.org/abs/2504.14225
- Recalling a changed preference: 60% to 70%. Applying the latest one: 30% to 50%. Quoted:
  "Incorporating the latest user preference into responses is more challenging than recalling the
  change in user profile."
- Items in the middle of a long history were used worst.
- Import: when the person reverses a verdict, retire the old item. Do not leave both for the model
  to sort out.

**Retest.** I found no study of one annotator re-judging LLM outputs weeks later. Measure it on our
person directly.

### Storing the examples

**PLUS, "Learning to Summarize User Information for Personalized RLHF"** (ICLR 2026).
https://arxiv.org/abs/2507.13579. A trained 3B summariser beat raw history: 69.4 against 59.6 on
UltraFeedback-P2. An untrained summariser did not (59.9). Summaries help only when they are
checked against held-out labels.

**PRIME** (EMNLP 2025). https://arxiv.org/abs/2507.04607. Distilled "semantic memory" generally
beat raw "episodic memory" (Change-My-View 37.2 against 30.8 on Qwen2.5-14B). Quoted: "the most
recent interactions tend to be the strongest predictors of immediate user behavior."

**Mem0** (April 2025). https://arxiv.org/abs/2504.19413. On LOCOMO: full context 72.9, Mem0 66.9
to 68.4, best RAG 61.0. Memory systems save tokens and time, not accuracy.

**ExpeL** (AAAI 2024, https://arxiv.org/abs/2308.10144) and **Agent Workflow Memory**
(https://arxiv.org/abs/2409.07429) keep both distilled rules and raw cases. That is the same
two-store shape as MemAlign.

Summary of the storage evidence: keep raw items as the record. Add distilled rules only when they
pass a held-out check. While everything fits, put everything in.

### Choosing what goes in context

**LaMP** (ACL 2024). https://arxiv.org/abs/2304.11406. Dense retrieval was best on most
classification tasks. Recency won on time-split tasks. Even random items from the person's history
beat none.

**KATE** (https://arxiv.org/abs/2101.06804) and **EPR** (https://arxiv.org/abs/2112.08633).
Retrieve the most similar examples (KATE). Or train a retriever on which examples raise the
probability of the right answer (EPR). EPR is the template for learning which of the person's past
verdicts predict new ones.

**MIPROv2 in DSPy** (EMNLP 2024). https://arxiv.org/abs/2406.11695. Picks demonstrations and
instructions together, by mini-batch scores on held-out items. Up to 13% gain with Llama-3-8B.

**Fermi** (NAACL 2025). https://aclanthology.org/2025.naacl-long.598. Optimises a prompt per user
from the cases the model got wrong, then at inference retrieves the prompt that scored best on
similar items. About 20 opinions per user. OpinionQA 54.6% against 49.8% for retrieved examples;
GlobalOpinionQA 74.8% against 61.2%.

## 2. Training a simulator of one person

### Frozen model, adapted prompt: what works with tens to hundreds

**MemAlign in MLflow** (Databricks, blog February 2026). https://mlflow.org/blog/memalign/ ;
https://mlflow.org/docs/latest/genai/eval-monitor/scorers/llm-judge/memalign/
- Quoted: it "lets LLM judges adapt to human feedback without updating model weights."
- Two stores: principles distilled from feedback, and hard cases retrieved per input (k=5).
  Records can be deleted or overwritten.
- 10 datasets, 50 training examples each. Gains after 2 to 10 examples. About $0.03 and 40 s per
  alignment, against $1 to $5 and 9 to 85 minutes for DSPy optimisers. About 1 s added per
  evaluation.
- On unseen items it led on one criterion and roughly tied on the rest. Vendor numbers, not peer
  reviewed. The judge was GPT-4.1-mini.
- Import: the two-store design, as-is. The `reflection_lm` can point at any provider; a local model
  is untested.

**SynthesizeMe** (ACL 2025). https://arxiv.org/abs/2506.05598. New detail beyond the earlier
survey: it also built PersonalRewardBench (131 Chatbot Arena users, 720 PRISM users). A
non-personalised reward model fine-tuned on all users reached about 71.5%. The authors: "Finetuned
Reward Models are a strong baseline given enough data." VPL and PAL scored 55% to 61% on the same
benchmark, below SynthesizeMe's 61.6%.

**HyPerAlign** (2025). https://arxiv.org/abs/2505.00038. From a handful of a person's samples, the
model writes hypotheses about their style and strategy, then prompts with them. No fine-tuning.

**GEPA** (ICLR 2026 oral). https://arxiv.org/abs/2507.19457 ; https://github.com/gepa-ai/gepa
(pushed 2026-10-09)
- Quoted: "a prompt optimizer that thoroughly incorporates natural language reflection to learn
  high-level rules from trial and error."
- On Qwen3-8B across six tasks: baseline 45.2, GRPO with LoRA 48.9 (24,000 rollouts per task),
  MIPROv2 47.8, GEPA 54.9 (1,800 to 7,000 rollouts per task).
- For a person-specific judge, a rollout is one judged item. Hundreds of the person's labels can be
  reused across rollouts.

**BetterTogether** (EMNLP 2024). https://arxiv.org/abs/2407.10930. Alternating prompt optimisation
and fine-tuning beat weights-only by up to 60% and prompts-only by up to 6%. Quoted: "optimizing
prompts is essential on all the tasks." In DSPy.

**Judge alignment in other tools.** LangSmith stores human corrections of a judge as few-shot
examples in its prompt (https://docs.langchain.com/langsmith/create-few-shot-evaluators). Arize
advises a set of "50 to a few hundred" labelled items and per-label precision and recall
(https://arize.com/docs/ax/evaluate/align-evals-to-human-feedback). Dropbox calibrated its judges
with GEPA and MIPROv2 on a small human-labelled set
(https://dropbox.tech/machine-learning/how-we-turned-ai-evaluations-into-better-responses-in-dash-chat).
None publish agreement numbers.

**Can LLM be a Personalized Judge?** (Findings of EMNLP 2024). https://arxiv.org/abs/2406.11657.
Already covered. The relevant point: with the judge's own certainty used to abstain, agreement
on the kept items exceeded 80%, comparable to third-party human raters.

### Fine-tuning to one person: when it wins

**OPPU, One PEFT Per User** (EMNLP 2024). https://arxiv.org/abs/2402.04401 ;
https://github.com/TamSiuhin/OPPU
- A rank-8 LoRA per user on Llama-2-7B, combined with retrieval and a profile.
- Users had 55 to 960 history items each.
- LaMP rating error: none 0.223, best retrieval 0.214, OPPU with profile 0.143.
- 100 users took 12 minutes to 12 hours on 3 A6000s.
- The strongest evidence for a per-person LoRA. It is at hundreds of items per person.

**CHiL(L)Grader** (March 2026). https://arxiv.org/abs/2603.11957. Section 3 has the details. A 7B
LoRA updated from a teacher's corrections, with replay. 2 GPUs, about 90 minutes.

**LLM-Rubric** (ACL 2024, Microsoft). https://arxiv.org/abs/2501.00274 ;
https://github.com/microsoft/llm-rubric (pushed 2026-09-17)
- The LLM answers a 9-question rubric and outputs a probability per answer. A small network "with
  both judge-specific and judge-independent parameters" predicts each human rater's scores.
- Error below 0.5 on a 1-to-4 scale, about 2x better than uncalibrated.
- The closest published design to a frozen LLM plus a tiny per-person calibrator. Training is
  seconds on a CPU-sized network.

**Misra et al., "Principled Fine-tuning of LLMs from User-Edits"** (NeurIPS 2025).
https://arxiv.org/abs/2601.19055. Treats one edit as three signals: a preference pair, a target
text and a cost. An ensemble of the three beat any one on the PRELUDE tasks. No numbers in the
abstract.

**Centaur** (Binz et al., Nature 2025). https://arxiv.org/abs/2410.20268
- A rank-8 QLoRA on Llama-3.1-70B, one epoch over 10.7M choices from 60,000 people.
- "About five days on a single A100 80GB" with Unsloth.
- Shows that one GPU can fine-tune a 70B dense model. A few hundred items would take minutes to
  hours. It is not about one person.

**Beyond Demographics** (2025). https://arxiv.org/abs/2502.20897. Fine-tuned models gained
"largely due to models learning annotator-specific behaviour rather than sociodemographic
patterns." So a person's own signal is learnable. Sizes not extracted.

**Against fine-tuning at small size.** Twin-2K-500's fine-tuned model (69.6%) did not beat the
persona prompt (71.7%). "Item-Mean Surrogates" (https://arxiv.org/abs/2608.29455, 2026) found
fine-tuned twins learned item-level patterns that did not carry to new studies.

### Personalised reward models: they need many people

All of these learn a shared base from many users, then fit a new user from a few labels. With one
person, the base is missing. I list them so the choice not to use them is on record.

- **LoRe** (Meta, 2025). https://arxiv.org/abs/2504.14439. A user is a weighted mix of shared basis
  rewards. On PRISM, unseen users with about 4 labels: 71.0%, against VPL 58.2% and PAL 59.0%.
- **PAL** (ICLR 2025). https://arxiv.org/abs/2406.08469. Each user is a mix over K prototypes.
- **VPL** (NeurIPS 2024). https://arxiv.org/abs/2408.10075. A per-user latent from 2 to 8
  comparisons. A 2026 follow-up reports the latent collapses with sparse data.
- **FSPO** (ICLR 2026). https://arxiv.org/abs/2502.19312. Meta-trained on more than 1M synthetic
  preferences over 1,500 synthetic users. 72% win rate with real users.
- **MRM** (SIGIR 2026). https://arxiv.org/abs/2601.18731. Meta-learned starting weights.
- **P-GenRM** (ICLR 2026). https://arxiv.org/abs/2602.12116. About 75.9% on Chatbot Arena users.
- **P-RLHF** (https://arxiv.org/abs/2402.05133), **Personalized Soups**
  (https://arxiv.org/abs/2310.11564), **MaxMin-RLHF**: about groups or declared dimensions, not
  one person.
- **User-embedding methods** (User-LLM https://arxiv.org/abs/2402.13598, PPlug
  https://arxiv.org/abs/2409.11901, Embedding-to-Prefix https://arxiv.org/abs/2505.17051): all
  need an encoder trained across many users.

### Judges trained on rubrics: what we could use without training

- **RewardAnything** (June 2025). https://arxiv.org/abs/2506.03637. A reward model that follows
  natural-language principles given at inference, "much like instruction-following." The most
  direct "steer with the person's own rubric" option among trained judges.
- **Prometheus 2** (2024). https://arxiv.org/abs/2405.01535 ;
  https://github.com/prometheus-eval/prometheus-eval (pushed 2025-04). 7B and 8x7B. Takes a
  user-written rubric: one criterion plus a description per score 1 to 5. About 71% to 72%
  pairwise accuracy on MT-Bench human judgments.
- **JudgeLM** (ICLR 2025, https://arxiv.org/abs/2310.17631), **J1** (Meta, ICLR 2026,
  https://arxiv.org/abs/2505.10320), CompassJudger, Skywork-Critic, Selene: general judges. Huang et
  al. (https://arxiv.org/abs/2403.02839): "Fine-tuned Judge Model is not a General Substitute for
  GPT-4." They are strong in their own domain and weak outside it.
- Our local 80B models are larger than all of these. A trained small judge is useful only as a fast
  first pass.

### Costs on local GPUs

From Unsloth's documentation (https://unsloth.ai/docs/basics/faster-moe, February 2026):
- 4-bit QLoRA does not currently work for MoE models; bitsandbytes cannot quantise the expert
  weights. Use bf16 LoRA.
- Qwen3-30B-A3B bf16 LoRA: about 63 GB; about 81 to 86 GB at rank 64 on an H100.
- GLM-4.7-Flash LoRA at rank 64: 58 to 63 GB.
- Qwen3-Next bf16 LoRA "fit on a single B200" (192 GB). I found no exact figure, and none from
  ms-swift or LLaMA-Factory.
- Arithmetic, not measured: an 80B model's bf16 weights alone are about 160 GB.

Prompt-side costs: SynthesizeMe and GEPA take hundreds to a few thousand judge calls per refit,
offline. MemAlign takes a few calls. Simulated Annotators take K×N calls per item, up to 25.

### How these are evaluated

- Held-out accuracy per person, with the person's items split by time or at random (SynthesizeMe,
  LoRe, PersonalRewardBench).
- Accuracy divided by the person's own retest (Park 0.85; Twin-2K-500 0.88).
- Cohen's kappa rather than percent agreement (Judging the Judges).
- Correlation with the person on items where people differ (Funhouse Mirrors), because easy items
  inflate accuracy.

## 3. Review on behalf of someone

The overall finding: production systems almost never learn one reviewer's standard in the model's
weights. They learn a team's standard in three cheap ways. Readable rules retrieved at review time.
Filters built from what was accepted or acted on. Thresholds that leave uncertain cases to the
human. Weight updates for one person appear only in research. I found no published system that
learns one named reviewer's standard and is measured against that reviewer.

### Code review

**Google AutoCommenter** (AIware 2024). https://arxiv.org/abs/2405.13565
- A model in the DIDACT family trained on reviewer comments that cite a best-practice document.
  Outputs a location, the cited practice and a confidence. Quoted: "Our priority was to ensure a
  positive developer experience by designing AutoCommenter to have very high precision."
- Confidence threshold 0.98 at first, later one threshold per practice.
- Useful ratio plateaued at about 54%. Suppressing 17 practices that drew negative feedback raised
  it to 66% (developers) and 74% (raters); five more passed 80%. Quoted: "a simple suppression
  mechanism was sufficient to strongly improve user acceptance to over 80%."
- Only about 10% of comments got explicit feedback.
- How approvals feed back: they change the suppression list and thresholds, not the weights.
- Import as-is: a per-kind suppression list, driven by the person's rejections.

**Google, "Resolving code review comments with ML"** (blog, May 2023).
https://research.google/blog/resolving-code-review-comments-with-ml/
- Proposes the edit that resolves a reviewer's comment. "Calibrated for a 50% target precision";
  nothing is shown below it.
- 7.5% of all reviewer comments were resolved by an ML edit.
- Negative feedback clusters became filter rules at serving time.

**Meta MetaMateCR** (FSE 2026 Industry). https://arxiv.org/abs/2507.13499
- Llama fine-tuned on 64,000 (comment, patch) pairs: 18,000 human-labelled, 46,000 labelled by a
  classifier trained on those.
- Showing AI patches to reviewers raised review time by 5.5% (p=0.029), so it was rolled back.
  Showing them only to authors caused no regression.
- Lesson for us: an AI draft shown to the approver costs the approver checking time. Measure the
  person's time, not only agreement.

**Atlassian RovoDev Code Reviewer** (ICSE-SEIP 2026). https://arxiv.org/abs/2601.01129
- A frozen model writes comments. A small judge checks facts. A ModernBERT classifier, trained on
  more than 50,000 past comments labelled by whether they led to a code change, filters for
  "actionable".
- One year, 54,000 comments: resolution rate 38.7% against 44.5% for human comments.
- The filter added about 20 points.
- Import: train the filter on "did the person act on it", which is plentiful and implicit.

**Greptile** (2024–25). https://www.greptile.com/blog/make-llms-shut-up ;
https://www.greptile.com/docs/how-greptile-works/memory-and-learning
- Asking a model to score comment severity was "nearly random."
- Method: embed every comment the team upvoted, downvoted, addressed or ignored. Block a new comment
  similar to 3 or more downvoted ones; pass one similar to 3 or more upvoted ones.
- Address rate rose from 19% to more than 55% in two weeks.
- They chose "address rate" (comment fixed before merge) over thumbs as the metric.
- Import as-is: the nearest-neighbour veto over the person's rejected items. No model call.

**CodeRabbit "Learnings".** https://docs.coderabbit.ai/knowledge-base/learnings. When a user tells
the bot a preference, it stores a short natural-language rule, scoped to a file, repository or
organisation. Up to 20 recent rules load before each review. Admins can require approval of a rule
before it takes effect. No effectiveness numbers.

**Qodo auto best practices.** https://qodo-merge-docs.qodo.ai/core-abilities/auto_best_practices.
Detects which suggestions authors accepted. Distils them into a repository rules file, checked in
a second pass and labelled "Learned best practice." No numbers.

**GitHub Copilot code review** (2026).
https://github.blog/ai-and-ml/github-copilot/60-million-copilot-code-reviews-and-counting/. 29% of
reviews stay silent. Tracks thumbs and whether issues are resolved before merge. Learning a team's
"unwritten preferences" is listed as future work.

**Earlier and research work.**
- RevMate (Mozilla and Ubisoft, 2024, https://arxiv.org/abs/2411.07091): 7% to 8% of comments
  accepted. Reviewers took a median 42.9 s per patch to triage.
- Beko field study of Qodo PR-Agent (ICSE-SEIP 2025, https://arxiv.org/abs/2412.18531): 73.8% of
  bot comments marked resolved, but pull-request closing time rose from 5h52m to 8h20m.
- Lin et al., experience-aware loss (TOSEM 2025, https://arxiv.org/abs/2409.10959): weights
  training comments by the reviewer's ownership of the code. +29% applicable comments. It favours
  experienced reviewers in general, not one reviewer.
- "Too Noisy To Learn" (MSR 2025, https://arxiv.org/abs/2502.02757): cleaning the human comments
  first gave better generated comments. The quality of the person's examples bounds what can be
  learned.
- CodeReviewer (FSE 2022, https://arxiv.org/abs/2203.09095), AutoTransform (ICSE 2022), LLaMA-
  Reviewer (ISSRE 2023, https://arxiv.org/abs/2308.11148): the baseline line of work. None learns
  one person.

### Writing assistants that learn an editor

**CIPHER / PRELUDE** (NeurIPS 2024). https://arxiv.org/abs/2404.15269. New details: cost is token
edit distance summed over 200 rounds. On email, no learning 31,103, CIPHER 8,391 (73% less),
oracle 1,851. On summaries, 31% less. Token cost about 1.3x to 2x.

**PROSE** (ICML 2025). https://arxiv.org/abs/2505.23815. 33% better than CIPHER on a scale where
0% is no conditioning and 100% the oracle. With in-context examples, 9% better than examples alone.
The users were simulated by GPT-4o.

**LaMP-QA** (EMNLP 2025, https://arxiv.org/abs/2506.00137): personal context gives up to 39%.

### Grading assistants calibrated to one teacher

**CHiL(L)Grader** (March 2026). https://arxiv.org/abs/2603.11957. The closest published system to
"the person only approves or corrects."
- Qwen-2.5-7B grader. Temperature-scaled confidence on a held-out split of about 260 to 540 items.
  It "automates only high-confidence predictions while routing uncertain cases to human graders."
- The teacher grades the routed items. LoRA is updated on those corrections plus a replay buffer
  (3 similar old examples per question). Then confidence is recalibrated.
- Without replay, agreement fell to a quadratic weighted kappa (QWK) of 0.025.
- Auto-grades 35% to 65% of answers at QWK 0.80 or more. Example: QWK 0.882 at 35.1% coverage.
- 2 RTX A5500 GPUs, about 90 minutes for the first tuning.
- Limits: corrections were simulated from ground-truth labels. Human-human agreement not reported.
- Import as-is: the loop of route, correct, update with replay, recalibrate.

**Pensieve Grader** (2025). https://arxiv.org/abs/2507.01431
- Each grade gets high, medium or low confidence. The instructor can trust only high.
- In a calibration step the instructor corrects a few grades. The differences become editable
  "grading wisdoms": readable rules.
- 95.4% agreement with instructors on high-confidence items; 65% grading time saved. Vendor numbers.
  The share of grades that were high-confidence is not reported.

**GradeHITL** (2025). https://arxiv.org/abs/2504.05239. The model asks the human about its own
grading errors, top k by confidence. An answer is kept only if it improves grading on a validation
set. QWK 0.87 against 0.80 for the prompt-optimisation baseline on one question; tied on another.

**CoTAL** (2025). https://arxiv.org/abs/2504.02323. Teacher feedback revises the rubric and prompt
in a loop. Up to 38.9% over no examples.

**Ceilings in grading.** A December 2025 review of 65 studies found LLM-human agreement mostly 0.30
to 0.80, with no standard reporting (https://arxiv.org/abs/2512.14561). Human-human QWK on essay
sets is about 0.77 to 0.91. Gains from a teacher's own graded examples were small and inconsistent
(one biology course: correlation 0.53 to 0.56).

### Moderation calibrated to a policy owner

**OpenAI, "Using GPT-4 for content moderation"** (August 2023).
https://openai.com/index/using-gpt-4-for-content-moderation/
- Experts label a small golden set. The model labels it blind. Experts "examine the
  discrepancies, ask GPT-4 for reasoning behind its labels, analyze ambiguity in policy
  definitions" and edit the policy. Repeat.
- Policy iteration went "from months to hours."
- What the human corrects is the policy text, not the model.
- Import as-is: the disagreement review. Show the person the items where the simulator disagreed
  with them, with its reasoning. Their fix is a rule edit or a new example.

**gpt-oss-safeguard** (OpenAI, October 2025). https://huggingface.co/openai/gpt-oss-safeguard-20b.
Open 20B and 120B models "trained to reason from a provided policy" given at inference. Outputs a
label and the reasoning. OpenAI states classifiers trained on "tens of thousands of high-quality
labeled samples can still perform better." Benchmark numbers are from secondary sources,
unverified.

**Llama Guard** (https://arxiv.org/abs/2312.06674) and **ShieldGemma**
(https://arxiv.org/abs/2407.21772): the policy is in the prompt. No published loop with a policy
owner.

**Constitutional Classifiers** (Anthropic, 2025–26).
https://www.anthropic.com/research/constitutional-classifiers. A written constitution generates
synthetic training data for classifiers. Jailbreak success fell from 86% to 4.4%. Calibration to
the owner is done by editing the constitution.

**Escalation.** Bachar et al. (AAMAS 2026, https://arxiv.org/abs/2601.07006): a small model on
log-probabilities decides trust or escalate under a cost model. It separates "evidence deficit" (the
item is unclear) from "policy gap" (the rules do not cover it). Lai et al. (CHI 2022,
https://arxiv.org/abs/2204.11788): the human writes rules for where the model may act alone.

### Measuring agreement and deferring

**Trust or Escalate** (Jung, Brahman, Choi; ICLR 2025 oral). https://arxiv.org/abs/2407.18370
- Guarantee: the judge agrees with humans at least 1−α of the time on items it keeps, with
  probability at least 1−δ. The threshold is chosen on 392 to 500 human-labelled items, δ=0.1.
- "Simulated Annotators": prompt the judge as several annotators, each with K examples, N times (K,
  N up to 5). Their agreement is the confidence.
- Chatbot Arena: more than 80% agreement at 79.1% coverage. GPT-4 alone almost never reaches 80%.
  TL;DR: 90% target at 55.7% coverage.
- Import as-is: Simulated Annotators, with the person's own example subsets as the K shots.

**Alternative Annotator Test** (Calderon et al., 2025). https://arxiv.org/abs/2501.10970
- Asks whether an LLM can replace a human annotator. Leave one human out; compare the LLM's
  agreement with the rest against the held-out human's agreement with the rest.
- Needs at least 3 annotators and 50 to 100 items. With one person it does not apply. It would
  apply if two other people labelled the same items; then it tests whether the simulator is as
  close to the Director as a colleague is.

**Judging the Judges** (Thakur et al., GEM 2025). https://arxiv.org/abs/2406.12624. Use kappa, not
percent agreement. Best judges reached kappa 0.79 to 0.84 against 0.96 human-human. Judges with high
agreement could still rank systems badly.

**Judge's Verdict** (NVIDIA, 2025). https://arxiv.org/abs/2510.09738. 54 judges against a
human-human kappa of 0.801. 4 were "super-consistent": they agreed more tightly than humans do. Too
much consistency is also a sign of not being human.

**Conformal intervals for judges** (EMNLP 2025, https://arxiv.org/abs/2509.18658): coverage
guarantees, again needing human calibration labels.

### How the person's approvals feed back

Four patterns, from the systems above:
- **Suppression and thresholds** (Google AutoCommenter): rejections switch off a kind of comment.
- **A filter trained or retrieved from "was it acted on"** (Atlassian, Greptile): implicit signals
  are far more plentiful than explicit ones; Google got explicit feedback on only 10% of comments.
- **Readable rules retrieved at review time** (CodeRabbit, Qodo, MemAlign, Pensieve's grading
  wisdoms, Databricks ALHF). ALHF (https://www.databricks.com/blog/agent-learning-human-feedback-alhf-databricks-knowledge-assistant-case-study):
  adherence to feedback rose from 11.7% to about 80% with 32 feedback records.
- **Weight updates with replay** (CHiL(L)Grader): research only.

## Sources

Section 1
- Random Is Hard to Beat: https://arxiv.org/abs/2604.02766
- Gleave and Irving 2022: https://arxiv.org/abs/2203.07472
- Margatina et al. 2023: https://arxiv.org/abs/2305.14264
- vote-k: https://arxiv.org/abs/2209.01975 ; https://github.com/HKUNLP/icl-selective-annotation
- Active sampling for LLM-judge prompts: https://aclanthology.org/2025.acl-industry.67/
- ActiveUltraFeedback: https://arxiv.org/abs/2603.09692
- EvalGen: https://arxiv.org/abs/2404.12272
- AutoLibra: https://arxiv.org/abs/2505.02820
- Park et al. 1,000 people: https://arxiv.org/abs/2411.10109
- GATE: https://arxiv.org/abs/2310.11589
- OPEN: https://arxiv.org/abs/2403.05534
- Pep/CAPE: https://arxiv.org/abs/2602.15012
- PrefDisco: https://arxiv.org/abs/2510.00177
- PREDICT: https://arxiv.org/abs/2410.06273
- Lampinen et al. 2022: https://arxiv.org/abs/2204.02329
- ILF: https://arxiv.org/abs/2303.16755
- Kreutzer et al. 2018: https://aclanthology.org/P18-1165/
- Many-Shot ICL: https://arxiv.org/abs/2404.11018
- Bertsch et al.: https://arxiv.org/abs/2405.00200
- Many-shot ICL for judges: https://arxiv.org/abs/2406.11629
- ICL for instruction following: https://arxiv.org/abs/2405.19874
- Twin-2K-500: https://arxiv.org/abs/2505.17479
- Digital Twins as Funhouse Mirrors: https://arxiv.org/abs/2509.19088
- Synthetic Personalities (SOEP): https://arxiv.org/abs/2606.04592
- Fermi: https://aclanthology.org/2025.naacl-long.598
- LeWiDi 2025: https://arxiv.org/abs/2509.09524 ; https://arxiv.org/abs/2510.07105 ; https://arxiv.org/abs/2506.06113
- NS-DPO: https://arxiv.org/abs/2407.18676
- PersonaMem: https://arxiv.org/abs/2504.14225
- PLUS: https://arxiv.org/abs/2507.13579
- PRIME: https://arxiv.org/abs/2507.04607
- Mem0: https://arxiv.org/abs/2504.19413
- LongMemEval: https://arxiv.org/abs/2410.10813
- ExpeL: https://arxiv.org/abs/2308.10144
- Agent Workflow Memory: https://arxiv.org/abs/2409.07429
- LaMP: https://arxiv.org/abs/2304.11406
- KATE: https://arxiv.org/abs/2101.06804
- EPR: https://arxiv.org/abs/2112.08633
- MIPRO: https://arxiv.org/abs/2406.11695

Section 2
- MemAlign: https://mlflow.org/blog/memalign/ ; https://mlflow.org/docs/latest/genai/eval-monitor/scorers/llm-judge/memalign/ ; alignment overview https://mlflow.org/docs/latest/genai/eval-monitor/scorers/llm-judge/alignment/
- SynthesizeMe: https://arxiv.org/abs/2506.05598 ; https://github.com/SALT-NLP/SynthesizeMe
- HyPerAlign: https://arxiv.org/abs/2505.00038
- GEPA: https://arxiv.org/abs/2507.19457 ; https://github.com/gepa-ai/gepa
- BetterTogether: https://arxiv.org/abs/2407.10930
- Mosbach et al. 2023: https://arxiv.org/abs/2305.16938
- LoRA Learns Less and Forgets Less: https://arxiv.org/abs/2405.09673
- TextGrad: https://arxiv.org/abs/2406.07496
- LangSmith few-shot evaluators: https://docs.langchain.com/langsmith/create-few-shot-evaluators
- Arize align evals: https://arize.com/docs/ax/evaluate/align-evals-to-human-feedback
- Dropbox Dash: https://dropbox.tech/machine-learning/how-we-turned-ai-evaluations-into-better-responses-in-dash-chat
- Personalized Judge: https://arxiv.org/abs/2406.11657
- OPPU: https://arxiv.org/abs/2402.04401 ; PER-PCS: https://arxiv.org/abs/2406.10471
- LLM-Rubric: https://arxiv.org/abs/2501.00274 ; https://github.com/microsoft/llm-rubric
- Principled fine-tuning from user edits: https://arxiv.org/abs/2601.19055
- Centaur: https://arxiv.org/abs/2410.20268
- Beyond Demographics: https://arxiv.org/abs/2502.20897
- Item-Mean Surrogates: https://arxiv.org/abs/2608.29455
- SubPOP: https://arxiv.org/abs/2502.16761
- HumanLM: https://arxiv.org/abs/2603.03303
- SimBench: https://arxiv.org/abs/2510.17516
- LoRe: https://arxiv.org/abs/2504.14439
- PAL: https://arxiv.org/abs/2406.08469
- VPL: https://arxiv.org/abs/2408.10075
- FSPO: https://arxiv.org/abs/2502.19312
- MRM: https://arxiv.org/abs/2601.18731
- P-GenRM: https://arxiv.org/abs/2602.12116
- Personalized RewardBench: https://arxiv.org/abs/2604.07343
- P-RLHF: https://arxiv.org/abs/2402.05133
- Personalized Soups: https://arxiv.org/abs/2310.11564
- MaxMin-RLHF: https://proceedings.mlr.press/v235/chakraborty24b.html
- User-LLM: https://arxiv.org/abs/2402.13598 ; PPlug: https://arxiv.org/abs/2409.11901 ; Embedding-to-Prefix: https://arxiv.org/abs/2505.17051
- RewardAnything: https://arxiv.org/abs/2506.03637
- Prometheus 2: https://arxiv.org/abs/2405.01535 ; https://github.com/prometheus-eval/prometheus-eval
- JudgeLM: https://arxiv.org/abs/2310.17631
- J1: https://arxiv.org/abs/2505.10320
- Fine-tuned judges are not a general substitute: https://arxiv.org/abs/2403.02839
- Unsloth MoE fine-tuning: https://unsloth.ai/docs/basics/faster-moe

Section 3
- AutoCommenter: https://arxiv.org/abs/2405.13565
- Google comment resolution: https://research.google/blog/resolving-code-review-comments-with-ml/
- MetaMateCR: https://arxiv.org/abs/2507.13499
- RovoDev Code Reviewer: https://arxiv.org/abs/2601.01129
- Greptile: https://www.greptile.com/blog/make-llms-shut-up ; https://www.greptile.com/docs/how-greptile-works/memory-and-learning
- CodeRabbit Learnings: https://docs.coderabbit.ai/knowledge-base/learnings
- Qodo auto best practices: https://qodo-merge-docs.qodo.ai/core-abilities/auto_best_practices
- Copilot code review: https://github.blog/ai-and-ml/github-copilot/60-million-copilot-code-reviews-and-counting/
- RevMate: https://arxiv.org/abs/2411.07091
- Beko field study: https://arxiv.org/abs/2412.18531
- Experience-aware loss: https://arxiv.org/abs/2409.10959
- Too Noisy To Learn: https://arxiv.org/abs/2502.02757
- CodeReviewer: https://arxiv.org/abs/2203.09095 ; LLaMA-Reviewer: https://arxiv.org/abs/2308.11148
- CRScore: https://aclanthology.org/2025.naacl-long.457 ; DeepCRCEval: https://arxiv.org/abs/2412.18291
- PRELUDE/CIPHER: https://arxiv.org/abs/2404.15269
- PROSE: https://arxiv.org/abs/2505.23815
- LaMP-QA: https://arxiv.org/abs/2506.00137
- CHiL(L)Grader: https://arxiv.org/abs/2603.11957
- Pensieve Grader: https://arxiv.org/abs/2507.01431
- GradeHITL: https://arxiv.org/abs/2504.05239
- CoTAL: https://arxiv.org/abs/2504.02323
- LLM grading review: https://arxiv.org/abs/2512.14561
- OpenAI GPT-4 moderation: https://openai.com/index/using-gpt-4-for-content-moderation/
- gpt-oss-safeguard: https://huggingface.co/openai/gpt-oss-safeguard-20b
- Llama Guard: https://arxiv.org/abs/2312.06674 ; ShieldGemma: https://arxiv.org/abs/2407.21772
- Policy-as-Prompt: https://arxiv.org/abs/2502.18695
- Constitutional Classifiers: https://www.anthropic.com/research/constitutional-classifiers ; https://arxiv.org/abs/2501.18837
- Trust-or-escalate for moderation: https://arxiv.org/abs/2601.07006 ; conditional delegation: https://arxiv.org/abs/2204.11788
- Trust or Escalate: https://arxiv.org/abs/2407.18370
- Alternative Annotator Test: https://arxiv.org/abs/2501.10970
- Judging the Judges: https://arxiv.org/abs/2406.12624
- Judge's Verdict: https://arxiv.org/abs/2510.09738
- Conformal judge intervals: https://arxiv.org/abs/2509.18658
- Databricks ALHF: https://www.databricks.com/blog/agent-learning-human-feedback-alhf-databricks-knowledge-assistant-case-study

## Metadata

- Numbers marked as vendor-reported (MemAlign, Pensieve, Greptile) are not peer reviewed.
- Not verified: exact numbers for the ACL 2025 active-sampling judge paper and for OPEN;
  gpt-oss-safeguard benchmark scores; the Bertsch crossover point; memory for an 80B MoE LoRA.
