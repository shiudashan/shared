# Survey: simulated users

This goes deeper than `survey-f5-surrogate-selfimprove-multimodal.md`. It does not repeat it.
Each entry gives a link, how alive it is (last push and stars, checked 2026-10-09), what we
would import, and the cost on a local model.

## Answer first: a recommended build

No single project does what we want. Our simulated user plays three parts: it writes seeds,
it plays rounds, and it critiques finished runs. It must learn from (evidence, reference
feedback) pairs. The build below puts together existing parts. Each part is named with its
source.

1. **Message shape: fixed guidelines plus a per-episode scenario (tau2-bench).** tau2 keeps
   one general guidelines file and puts everything specific to the episode in a
   `<scenario>` block: `reason_for_call`, `known_info`, `unknown_info`, `task_instructions`.
   For us, the guidelines are `prompts/director.txt`. The scenario is the seed, the view and
   the dataset entries. f4 already has this shape. Import the `unknown_info` idea as data:
   what the person does not know is listed, so "No preference." has a stated ground.

2. **Explicit end signals (tau2-bench, SimulatorArena, CollabLLM).** tau2 has three tokens:
   `###STOP###` (goal met), `###TRANSFER###` (handed on) and `###OUT-OF-SCOPE###` (the
   scenario says nothing). SimulatorArena's writer adds a fourth case: stop when "the
   conversation is no longer productive". For us these map to: approve and stop; pass the
   item to the human (no ground, so escalate); and abandon the run ("not worth reading").
   The last one matters because simulated users "never walk away" (see section 2).

3. **Learning feedback from pairs, as data (SynthesizeMe, CIPHER, PROSE).** This is the core.
   - CIPHER (PRELUDE code): store each past context with the preference inferred from the
     person's edit. For a new context, retrieve the k nearest (k=3 in the code) by embedding
     and merge them. No model training.
   - SynthesizeMe (ACL 2025, code on GitHub): split one user's labelled pairs into train and
     validation. Have the model reason about each train pair; keep only reasoning that
     reaches the true label. Write a short persona from the kept reasoning. Then pick, by
     validation accuracy, which pairs to show as few-shot demos. Everything learned is
     either readable text or a choice of examples.
   - PROSE (Apple, ICML 2025): refine the inferred preference over several passes, and keep
     it only if it holds across several of the user's samples. Reported 33% better than
     CIPHER.
   For f: an entry in `director-data/complaints/` is one (evidence, reference feedback)
   pair. The complain prompt stays general. What changes per run is which entries are
   shown (CIPHER's retrieval by similarity of run facts) and which entries earn a place
   (SynthesizeMe's selection on held-out entries). An inferred rule, if any, is a dataset
   entry the Director approves, not a prompt edit.

4. **Evidence computed by code, not read by the model (TRAIL, AutoLibra).** TRAIL shows that
   strong models find only about 11% of annotated errors in long agent traces. So the
   simulator should not read raw logs. f4's `runfacts` already computes turn times, leaves
   written and overview lengths. AutoLibra (ICLR 2026) turns open-ended feedback on agent
   runs into named metrics with definitions and examples. Its two checks fit our dataset:
   coverage (how much of the held-out feedback the metrics explain) and redundancy. Import
   the idea: each reference complaint names the fact it rests on, and a new kind of
   complaint adds a fact to `runfacts`.

5. **Difficulty from controlled behaviour axes and from shards (Persona Policies, Lost in
   Conversation).** Persona Policies keeps the base prompt and appends a short block from
   binary axes such as terseness, skepticism, frustration and ambiguity. Lost in
   Conversation splits a full instruction into shards and reveals one per turn. For seeds:
   vary how much of the seed is given at once (shards over rounds) and how terse and
   skeptical the player is. Combine with the "learnable" band from the earlier survey to
   keep seeds f solves sometimes.

6. **A checker for the simulator itself (tau2's user-only review judge).** tau2 ships a
   judge that reads a finished conversation and flags simulator errors, tagged
   `hallucination`, `revealed_info_early`, `inconsistent_behavior`, `premature_termination`
   and more, with severity `critical_helped`, `critical_hindered` or `minor`. Import the
   taxonomy as-is. For us "hallucination" is feedback with no ground, and "critical_helped"
   is the simulator making f look better than the Director would.

7. **Tests a small team can run.** Replay held-out past rounds and runs; measure agreement
   with the Director, divided by the Director's own consistency; check that the simulator
   ranks two f versions the way the Director does; measure style features by code. Details
   in section 2.

Not recommended as the core: UserLM-8b (strong at sounding like a WildChat user, weaker at
role-play and overconfident by one 2026 study), and the framework simulators (promptfoo,
DeepEval, openevals, LangWatch). The frameworks are thin wrappers around a persona prompt
and a turn loop. Their prompts are worth reading; their code adds nothing f lacks.
promptfoo's simulated user does not run locally at all (see section 3).

**Cost on a local model, per round.** The round player is one call, as in f4. Retrieval of
the k nearest entries is an embedding lookup: no model call. The run critic is one call per
finished run. The self-check judge is one call per round, run offline on a sample. The
expensive part is SynthesizeMe-style selection: about 10 reasoning trials plus 10 demo
trials, each over the training entries. That is a few hundred calls per refit. Run it
between sessions, when the dataset changes, never inside a round.

## 1. Mechanisms

### Goal and instruction driven (best fit for the round player)

**tau2-bench** (Sierra Research). https://github.com/sierra-research/tau2-bench. Pushed
2026-10-07, about 2.2k stars; now includes the tau3 domains.
- One guidelines file plus a scenario per task. Persona is set in three places: the global
  guidelines, an optional per-task `persona` field, and a runtime `persona_config`. The
  code warns the three must not overlap.
- Tasks carry `known_info` and `unknown_info`. The guidelines say information not given
  "should be considered unknown or unavailable".
- Difficulty is written into `task_instructions`, e.g. "Don't accept the first offer, be
  insistent. If after a few attempts you can't get a better offer, accept."
- Stops on `###STOP###`, `###TRANSFER###`, `###OUT-OF-SCOPE###`.
- Import as-is: the scenario fields, the three end tokens, the user-only review judge.
- Cost: one call per user turn. The review judge is one call per conversation.
- Also ported to Inspect: `src/inspect_evals/tau2` in
  https://github.com/UKGovernmentBEIS/inspect_evals. Inspect itself has no general user
  simulator that I found.

**tau-bench** (the original). https://github.com/sierra-research/tau-bench. Pushed
2026-03-18, about 1.5k stars. Superseded by tau2, but it has two variants worth knowing.
`VerifyUserSimulationEnv` asks a supervisor model whether each user turn is satisfactory
and resamples up to 3 times. `ReflectionUserSimulationEnv` adds a reflection step before
resampling. Cost: up to 3–4 calls per user turn. Useful only if one-call turns are too
unreliable.

**Oracle users for underspecified work** (Ambig-SWE, LHAW, "Ask or Assume").
https://arxiv.org/abs/2502.13069 ; https://labs.scale.com/blog/LHAW. The simulated user
holds the full specification; the agent sees an underspecified one and must ask. Asking
recovers much of the lost performance, not all. Caveat from these papers: an oracle always
knows the answer, so results are optimistic. Import: the full seed as the oracle's hidden
material, the shortened seed as what f sees. This is one way to make seeds harder.

### Profile conditioning, learned from real data

**SimulatorArena** (Microsoft and Georgia Tech, EMNLP 2025).
https://arxiv.org/abs/2510.05444 ; https://github.com/microsoft/SimulatorArena (pushed
2026-05-12).
- 909 real human–assistant conversations, in math tutoring and document writing.
- Profiles are extracted by a model from each real user's conversations: what they know,
  their preferences (as question–answer pairs, e.g. "Does the user want headings...?"), and
  their writing and interaction style (12–17 attributes).
- Profiles raised agreement with human ratings of assistants from Spearman 0.61 to 0.77
  (math) and 0.55 to 0.70 (documents), at under 3% of the cost of humans.
- The profile is data (JSON files per user), not prompt text.
- Import: the document-creation prompt (quoted in section 3). It is the nearest existing
  prompt to "a person reviewing a draft and giving feedback". Also the idea of preferences
  as question–answer pairs extracted from past sessions.
- Cost: one call per turn, plus one offline call per user to extract a profile.

**RealUserSim** (Salesforce, 2026). https://arxiv.org/abs/2605.20204. Builds an
"Executable Persona Manual" of up to 15 "command + example" pairs per real user, each
example quoted from the user's own messages. Examples from the test conversation are
removed. Raised a paired Turing-test match rate from 24% to 45%. It names two failures we
must avoid: the "Formalism Ceiling" (simulators write polished text whatever the person's
style) and "Directive Amplification" (a line like "you are an angry customer" is pushed to
extremes, differently per model). Import: the quoted-example form, which is how f4 already
gives earlier rounds.

### Trained user models

**UserLM-8b** (Microsoft, ICLR 2026). https://huggingface.co/microsoft/UserLM-8b ; paper
https://arxiv.org/abs/2510.06552. MIT licence. Takes one input, the task intent, as a
system message. Can emit `<|endconversation|>`; its F1 at ending conversations is about 64
against 3–15 for prompted assistants. The card lists four generation guardrails: filter
first tokens, avoid early termination, length limits, filter verbatim repetition. Known
weaknesses: drifts from its role, adds facts. Import: only as a candidate seed writer, after
the tests in section 2. Cost: an 8B model, fast locally.

**StudentSim** (Microsoft, 2026 preprint). https://arxiv.org/abs/2609.01591. Trains one
simulator per student. Scores two things: behavioural fidelity and responsiveness to
guidance. It names a "competence paradox": prompted models are too capable to play a weaker
student. Lesson for us: a prompted simulator will tend to be a more competent Director than
the person. Not importable code.

### Learning a person's feedback from few examples

**SynthesizeMe** (Stanford and Georgia Tech, ACL 2025).
https://aclanthology.org/2025.acl-long.397 ; https://github.com/SALT-NLP/SynthesizeMe
(pushed 2025-06, 39 stars, built on DSPy).
- Steps: bootstrap reasoning on train pairs, keep only reasoning that reaches the true
  label, pick the best of 10 trials on validation pairs; write a persona from it; choose
  few-shot demos by validation score (best of 10).
- Typical user: 5 to 15 labelled pairs. That is the size of our complaint dataset.
- Results with Llama 3.1 8B as judge on Chatbot Arena users: 53.7% default, 61.6% with
  SynthesizeMe. A fine-tuned reward model still does better (68–70%), but needs training.
- Import: the procedure, applied to complaint entries. The learned parts are a persona text
  the Director can read and a list of chosen entries.
- Cost: offline, a few hundred calls per refit. Online: none beyond the normal call.

**CIPHER, in PRELUDE** (Microsoft, NeurIPS 2024). https://github.com/gao-g/prelude (pushed
2024-11, 46 stars; inactive but small and readable).
- `CipherNAgent`: retrieve the top 3 past contexts by BERT embedding, merge their inferred
  preferences with one call, write with the merged preference. After an edit, infer a new
  preference with one call and store it.
- The repo also has the baseline `get_task_prompt_icl`: raw (original, revised) pairs as
  in-context examples. That is the "examples as data" form in its plainest shape.
- Import: the retrieval, keyed on run facts instead of text.
- Cost: at most 2 extra calls per item; cacheable.

**PROSE** (Apple, ICML 2025). https://arxiv.org/abs/2505.23815 ;
https://github.com/apple-aiml-research/ml-predict (pushed 2026-09). Adds iterative
refinement and a check across several samples to CIPHER. It found that inferred preferences
and in-context examples work best together (up to 9% over examples alone). Import: the
cross-sample check: an inferred rule is kept only if it explains more than one reference
complaint.

**Preference agents** (UIUC, EMNLP 2024). https://arxiv.org/abs/2410.03731. A small local
model is fine-tuned to write natural-language rules that steer a large model. Fits later, if
the dataset grows past what fits in a message. Needs fine-tuning.

**Personalized judge** (Cambridge, EMNLP 2024 Findings). https://arxiv.org/abs/2406.11657 ;
https://github.com/dong-river/Personalized-Judge. A model judging for one person from a
persona agrees about 70% of the time on binary choices, below 60% on some tasks. Asking the
model for its confidence and keeping only high-confidence items raises agreement above 80%.
This supports f4's rule: decide only sure items, pass the rest to the person.

### Simulators that give feedback, not just answers

**PRELUDE's simulated user** (same repo). It holds a hidden preference. It first answers
yes or no: "Is the above email ... good for a user who wants the following style:
{preference}?" Only on "no" does it revise. This two-step accept-then-edit is the shape of
our review items: approval is the empty answer, otherwise feedback.

**MINT** (UIUC, ICLR 2024). https://github.com/xingyaoww/mint-bench. A model sees the
trajectory and the correct solution and gives feedback "similar to a teacher": guide, do not
give away the answer. One fixed in-context example is pasted in as prompt text. Shows that
the feedback giver may hold privileged information (the reference) that the agent lacks.

**CollabLLM** (Stanford and Microsoft, ICML 2025). https://github.com/Wuyxin/collabllm
(pushed 2025-09, about 300 stars). The simulated user sees the task and the reference goal,
hidden from the AI, and is told to "minimize effort" and "occasionally make mistakes". It
outputs a summary of the AI's current answer, a thought, and a response. It ends with a
terminal signal when the goal is met "or if you determine the AI cannot help further".

**Collaborative Gym** (Stanford SALT). https://github.com/SALT-NLP/collaborative-gym
(pushed 2026-08). A simulated user and an agent share a workspace, and the user can act on
it, not only talk. Closest to "edits structure". Import: the idea that the simulated
Director's actions on the board (moves, edits) are events in the same log as f's actions.

**Recommenders and tutoring.** iEvaLM-style recommender simulators were shown to leak the
target item into their replies, which inflates scores (https://arxiv.org/abs/2403.16416).
ConvApparel (Google, EACL 2026) adds a learned human-likeness score. In tutoring,
"Simulated Students: Substance or Illusion?" (ACL 2026, https://arxiv.org/abs/2601.04025)
finds prompting poor and fine-tuning better but limited. Lesson for us: the simulated
Director must not see what f is supposed to produce, or it will steer f to it.

### How simulators stop, refuse or escalate

- Fixed tokens: tau-bench `###STOP###`; tau2 adds `###TRANSFER###` and `###OUT-OF-SCOPE###`.
- A separate checker: DeepEval's controller asks, after each turn, whether the expected
  outcome is met and returns `is_complete` and `reason`.
- A trained token: UserLM-8b's `<|endconversation|>`.
- Walking away: SimulatorArena's writer stops when the conversation "is no longer
  productive"; CollabLLM's when "the AI cannot help further". Without such a line,
  simulators keep going: "Simulated Customers Never Walk Away"
  (https://arxiv.org/abs/2606.20708).
- Turn caps: openevals `max_turns` or a `stopping_condition` callable; promptfoo `maxTurns`
  (default 10).

### How they vary difficulty

- Written into the task: tau2's "be insistent", "don't accept the first offer".
- Information release: Lost in Conversation's shards, one per turn; tau's "Do not give away
  all the instruction at once."
- Behaviour axes: Persona Policies (https://arxiv.org/abs/2605.12894,
  https://github.com/harshita-chopra/persona-policies). Axes like terseness and skepticism
  are set on or off, then expanded into a policy appended to the unchanged base prompt.
  Blind annotators judged its users human 80% of the time, the same as real humans; the
  base simulator, 47%.
- Hidden knowledge: oracle users (Ambig-SWE) and knowledge levels per concept
  (SimulatorArena math profiles).

## 2. Tests

### What goes wrong (checked failure modes)

**Mind the Sim2Real Gap** (CMU, 2026). https://arxiv.org/abs/2603.11245. 31 simulators
against 451 people on tau-bench.
- Simulators are too cooperative and volunteer everything early. GPT-4o wrote short turns
  1% of the time; humans, 29%.
- Too polite: 49% polite turns against 15% for humans.
- They pivot instead of pushing back on errors.
- Agents succeed more often with simulators (up to 77.8%) than with humans (63.6%).
- Simulated ratings are more positive than human ratings.
- A more capable model is not a more faithful user. Persona prompting made things worse in
  their test (index 70.9 down to 64.6).
- Their index (USI) combines four behaviour groups, outcome calibration and rating agreement.
  Humans agree with each other at 92.7; the best simulator scores 76.0.

Other named failures: leaking the target (recommenders, above); the Formalism Ceiling and
Directive Amplification (RealUserSim); the competence paradox (StudentSim); never walking
away (decision fidelity). tau2's review judge gives a ready taxonomy of turn-level errors.

### Tests a small team can run

Each needs only the Director's past rounds and runs. None needs a human study.

1. **Held-out replay agreement.** Hide the Director's answer on past items; have the
   simulator predict it; score with f4's match mode. Divide by the Director's own
   consistency: ask the Director to redo a few old items blind. Park et al. use this
   normalisation for their 1,000-person agents (https://arxiv.org/abs/2411.10109); without
   it, a low score may be the person's own noise.
2. **Leave-one-run-out complaint recall and precision.** For each run with reference
   complaints, build the simulator from the other runs' entries only, and check which
   complaints it raises. f4's director spec already plans this on e2e-g7, e2e-g8 and
   e2e-i1-sim. Report misses and extra complaints separately: the extras are the
   "critical_helped" or "hindered" cases.
3. **Ranking agreement.** Give the simulator two runs from two f versions; does it prefer the
   one the Director preferred? SimulatorArena uses Spearman on ratings for this. For f this
   is the test that matters most, because the simulator's job is to choose between
   improvements.
4. **Style features by code.** Measure the simulator's answers and complaints against the
   Director's real ones: words per answer, share of one-line answers, share of "No
   preference.", share of empty approvals. These are the Sim2Real D1–D4 features reduced to
   what f records. They cost nothing to compute.
5. **Paired Turing test.** Show a model one real Director answer and one simulated answer to
   the same item, in both orders; can it tell which is real? Score |accuracy − 50%|
   (SimulatorArena, RealUserSim's PT3). One call per pair per order.
6. **Self-check judge.** Run tau2's user-only review prompt on a sample of simulated rounds.
   It catches answers with no ground and contradictions across rounds.
7. **Keep two sets apart.** Use different past runs to tune the simulator and to test it
   (a recommendation from the Sim2Real paper).

### Benchmarks for simulators

SimulatorArena (rating agreement, message similarity), the Sim2Real USI on tau-bench,
RealUserSim's fidelity index, ConvApparel (recommenders), StudentSimEval (tutoring),
PersonalRewardBench (personal judges, from SynthesizeMe). None covers a person steering a
plan. They are useful as method, not as a score for our simulator.

## 3. Prompts

Each entry: where the prompt lives, the key instructions quoted, its structure, and whether
the user's examples are data or prompt text.

**tau2-bench** `data/tau2/user_simulator/simulation_guidelines.md`, wrapped by
`src/tau2/user/user_simulator.py`:
- Template: `{global_user_sim_guidelines_with_persona}` then `<scenario>{instructions}</scenario>`.
- Key lines: "Never make up or hallucinate information not provided in the scenario
  instructions. Information that is not provided in the scenario instructions should be
  considered unknown or unavailable." "Disclose information progressively. Wait for the
  agent to ask for specific information before providing it." "If you find yourself in a
  situation in which the scenario does not provide enough information for you to continue
  the conversation, generate the '###OUT-OF-SCOPE###' token."
- Examples as data: yes. Everything specific lives in task JSON fields.

**tau2 user-only review judge** `src/tau2/evaluator/review_llm_judge_user_only.py`:
- "Fact-check every user claim ... Any detail not grounded in the instructions is a
  hallucination — even if it sounds plausible." "Do not blame the user for agent failures:
  If the agent is unresponsive ... the user giving up ... is a reasonable reaction."
- Output: a list of errors with `turn_idx`, `error_tags`, severity, reasoning.

**tau-bench** `tau_bench/envs/user.py`:
- "Do not give away all the instruction at once. Only provide the information that is
  necessary for the current step." "If the agent asks for the order id but it is not
  mentioned in the instruction, do not make up an order id, just say you do not remember or
  have it." "Do not repeat the exact instruction in the conversation."
- The ReAct variant asks for "Thought:" then "User Response:"; only the response is sent.

**SimulatorArena, document creation**
`simulation/prompts/document_creation/zero-shot-cot-user-profile.txt`:
- "Each message can involve asking questions, giving instructions or feedback, suggesting
  changes, etc., in a way a real user might." "Share your information and pre-writing
  materials gradually."
- Its thought step asks about "your satisfaction with the current writing style, tone, and
  content" and "your next priority in improving the document".
- End rule: output only "terminate conversation" if "You are satisfied with the final
  document" or "The conversation is no longer productive (e.g., it's going in circles, not
  addressing your needs, or the assistant's messages are unhelpful)".
- Examples as data: yes. `{user_profile}` is filled from per-user JSON extracted from real
  conversations.

**CollabLLM** `collabllm/prompts/user_simulator.txt`:
- Hidden blocks marked "(Not visible to the AI)" for the task and the reference goal.
- "Minimize Effort: IMPORTANT! As a user, avoid being too detailed in your responses."
  "Occasionally Make Mistakes." "Use "{terminal_signal}" as your response when you believe
  your goal has been solved or if you determine the AI cannot help further."
- Output JSON: `current_answer`, `thought`, `response`.

**Lost in Conversation** `prompts/user_agent.txt` (https://github.com/microsoft/lost_in_conversation,
pushed 2026-06, about 300 stars):
- "The user is inherently lazy, and answers in short form, providing only minimal
  information to the system. You should not be proactive."
- "[One Shard at a Time] You should only reveal at most one shard at a time." "[Irrelevant
  Clarifications] If the system asks you a question irrelevant to the shards ... respond
  with an answer that does not provide a shard." "[Do Not Ask Questions]".
- Output JSON: `response`, `shard_id` (-1 for none). The shard id makes leaks checkable by
  code.

**PRELUDE / CIPHER** `src/task/email_writing.py`:
- Preference inference: "Based on the edits and revision by this user on the original email
  in the above examples, what do you find about this user's generic preference in terms of
  writing style and formatting? Please answer in a short phrase and only recommend those
  preferences that are widely used."
- Merge: "Based on the the above examples, please come up with short phrase with the most
  represented writing preferences of this user."
- Examples as data: yes; retrieved from a store by embedding.

**SynthesizeMe** `synthesizeme/utils/prompts.py`:
- Judge objective: "Use any provided context as well as the provided persona to speculate
  about the personal preferences of the judge. You are a personalized reward model for this
  user."
- Demos are inserted as prior user/assistant turns, each with its reasoning and the true
  choice. Examples as data: yes, and selected by validation score.

**MINT** `mint/prompt/templates/template_feedback_agent.txt`:
- "Please provide concise and constructive feedback. Remember, your role is similar to a
  teacher. Rather than giving away the solution or details about the answer, guide the
  assistant toward understanding how to arrive at the correct answer."
- Examples: one fixed `{in_context_example}`, effectively prompt text.

**DeepEval** `deepeval/simulator/template.py` and `controller/template.py`
(https://github.com/confident-ai/deepeval, pushed 2026-10-07, about 18.7k stars):
- "Match the persona's tone faithfully. If the user is frustrated, impatient, blunt, or
  impolite, reflect that naturally instead of making them warm or courteous." "The
  generated user input should be concise, ideally no more than 1-2 sentences."
- A separate "Conversation Completion Checker" decides the end from `expected_outcome`.
- Examples as data: yes. Scenario, persona and expected outcome come from a
  `ConversationalGolden` dataset. Cost: two calls per turn (user turn plus checker).

**LangWatch Scenario** `python/scenario/user_simulator_agent.py`
(https://github.com/langwatch/scenario, pushed 2026-10-07, about 1k stars):
- "Approach this naturally, as a human user would, with very short inputs, few words, all
  lowercase, imperative, not periods." "YOU ARE NOT the assistant today, you are the user."
- It reverses roles before calling the model; its comment says models "are biased to always
  be the assistant not the user".

**openevals (LangChain/LangSmith)** `python/openevals/simulators/prebuilts.py`
(https://github.com/langchain-ai/openevals, pushed 2026-10-02, about 1.2k stars):
- No built-in prompt: the caller passes `system`. It also swaps roles. `fixed_responses`
  lets the first turns be scripted, then the model takes over. Stops on `max_turns` or a
  `stopping_condition` callable.
- Examples as data: only through scripted turns.

**promptfoo** `src/providers/simulatedUser.ts` (https://github.com/promptfoo/promptfoo,
pushed 2026-10-09, about 26k stars):
- The user's `instructions` is a per-test variable (data). Stops on `###STOP###` or
  `maxTurns`.
- The simulator prompt is not in the repo. The code posts the instructions and history to
  promptfoo's remote generation server, and fails if remote generation is disabled. It
  cannot run on a local model.

**Strands Evals** (AWS, https://github.com/strands-agents/evals, pushed 2026-10-08):
`ActorSimulator` gives the simulated user a goal-completion tool it can call to check its
own goal. I did not find the prompt text in the repo tree.

**Ragas, OpenAI and Anthropic cookbooks.** I found no user-simulator prompt in any of them.

Which treat feedback examples as data: tau2, SimulatorArena, PRELUDE/CIPHER, SynthesizeMe,
DeepEval, promptfoo and Lost in Conversation keep the person's material in data fields.
MINT pastes a fixed example into the prompt. Only SynthesizeMe and CIPHER also choose which
examples to show, by validation score or by similarity.

## Sources

- tau2-bench: https://github.com/sierra-research/tau2-bench ; guidelines https://github.com/sierra-research/tau2-bench/blob/main/data/tau2/user_simulator/simulation_guidelines.md ; review judge https://github.com/sierra-research/tau2-bench/blob/main/src/tau2/evaluator/review_llm_judge_user_only.py
- tau-bench: https://github.com/sierra-research/tau-bench/blob/main/tau_bench/envs/user.py
- Inspect tau2 port: https://github.com/UKGovernmentBEIS/inspect_evals/tree/main/src/inspect_evals/tau2
- SimulatorArena: https://arxiv.org/abs/2510.05444 ; https://github.com/microsoft/SimulatorArena
- RealUserSim: https://arxiv.org/abs/2605.20204
- Mind the Sim2Real Gap: https://arxiv.org/abs/2603.11245
- Persona Policies: https://arxiv.org/abs/2605.12894 ; https://github.com/harshita-chopra/persona-policies
- Simulated Customers Never Walk Away: https://arxiv.org/abs/2606.20708
- UserLM-8b: https://huggingface.co/microsoft/UserLM-8b ; https://arxiv.org/abs/2510.06552
- StudentSim: https://arxiv.org/abs/2609.01591
- Simulated Students in Tutoring Dialogues: https://arxiv.org/abs/2601.04025
- SynthesizeMe: https://aclanthology.org/2025.acl-long.397 ; https://github.com/SALT-NLP/SynthesizeMe
- PRELUDE / CIPHER: https://arxiv.org/abs/2404.15269 ; https://github.com/gao-g/prelude
- PROSE: https://arxiv.org/abs/2505.23815 ; https://github.com/apple-aiml-research/ml-predict
- Preference agents: https://arxiv.org/abs/2410.03731
- Can LLM be a Personalized Judge?: https://arxiv.org/abs/2406.11657 ; https://github.com/dong-river/Personalized-Judge
- Generative agent simulations of 1,000 people: https://arxiv.org/abs/2411.10109
- MINT: https://github.com/xingyaoww/mint-bench
- CollabLLM: https://github.com/Wuyxin/collabllm
- Collaborative Gym: https://github.com/SALT-NLP/collaborative-gym
- Lost in Conversation: https://arxiv.org/abs/2505.06120 ; https://github.com/microsoft/lost_in_conversation
- Ambig-SWE: https://arxiv.org/abs/2502.13069 ; LHAW: https://labs.scale.com/blog/LHAW ; Ask or Assume: https://www.alphaxiv.org/abs/2603.26233
- TRAIL: https://arxiv.org/abs/2505.08638
- AutoLibra: https://arxiv.org/abs/2505.02820
- Recommender simulator reliability: https://arxiv.org/abs/2403.16416 ; ConvApparel: https://research.google/pubs/convapparel-a-benchmark-dataset-and-validation-framework-for-user-simulators-in-conversational-recommenders/
- DeepEval: https://github.com/confident-ai/deepeval/tree/main/deepeval/simulator
- openevals: https://github.com/langchain-ai/openevals/tree/main/python/openevals/simulators
- promptfoo: https://github.com/promptfoo/promptfoo/blob/main/src/providers/simulatedUser.ts ; https://www.promptfoo.dev/docs/providers/simulated-user/
- LangWatch Scenario: https://github.com/langwatch/scenario/blob/main/python/scenario/user_simulator_agent.py
- Strands Evals: https://github.com/strands-agents/evals ; https://strandsagents.com/blog/simulate-realistic-users-multi-turn-agents-strands-evals/
