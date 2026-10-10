# Survey: how recent AI agents decide where to spend effort, and when to ask the person

Purpose: the Director asks whether agent systems from 2023 to 2026 already solve our three problems, so that f can copy a proven rule. The three problems:
1. A priority over work items anywhere in the tree, comparable across the whole tree.
2. How much work to do before the next round of human feedback.
3. Which items to put in front of the person, and when to ask at all, rather than decide or answer by proxy.

This follows the earlier survey, `survey-attention-speculation.md`, question A. Its picks were: value of computation as the key of one global queue (A1, A4), Horvitz thresholds for proxy versus ask (A5), and alert batching (A6).

Words used below.
- "Global ranking" means one score that orders every item in the tree against every other.
- "Local choice" means the system picks among a few options at one point, with no common score across the tree.
- "Fetched" means I read the source in this survey. "From memory" means I did not, and the detail should be checked before relying on it.

## Answer first

No recent agent system has a proven rule for all three problems. What they actually use is simple.
- For where to work: an LLM scores each candidate and the best is taken, sometimes with a fixed chance of picking something else. One system, Google's AI co-scientist, builds a true global ranking, by pairwise comparisons and Elo ratings.
- For how much work: hand-set budgets. A table of effort by task complexity in the prompt, fixed node counts per stage, a cost cap, or a message cap. None derive the budget from the value of more work.
- For when to ask: either the developer places the approval points in code, or the agent asks once at the start and then works alone. Two frameworks let several pending questions wait together and be answered in one pass. Only one research method, KnowNo, gives a rule for asking with a guarantee attached.

So the earlier survey's picks still stand as the decision rules. The recent systems give us better inputs to those rules, and the mechanics of batching. Details are under "Recommendation" at the end.

---

## 1. Anthropic

### 1a. Multi-agent research system (lead agent and subagents)

Mechanism. A lead agent plans with extended thinking, judges how complex the query is, and decides how many subagents to start. The prompt carries an effort-scaling table: simple fact-finding uses one agent with 3 to 10 tool calls; direct comparisons use 2 to 4 subagents with 10 to 15 calls each; complex research uses more than 10 subagents with clearly divided duties. The lead starts 3 to 5 subagents in parallel, reads their results, and decides whether to add more. The table was added because early versions spent far too much on simple queries, for example 50 subagents.

Global ranking or local. Local. The lead decides from its own reading. There is no score over tasks.

Effort bound. A hand-set table in the prompt, keyed by a complexity class the lead assigns. The loop ends "once sufficient information is gathered", with no numeric test.

Human involvement. None during a run. Humans appear only in evaluation.

Source (fetched): https://www.anthropic.com/engineering/multi-agent-research-system

### 1b. Claude Code subagents

Mechanism. The main agent delegates when a task matches a subagent's `description` field. Writing "use proactively" in the description makes delegation more eager. Independent investigations can run in parallel, up to 20 at once by default.

Global ranking or local. Local. Nothing public describes how Claude Code orders its work beyond the model's own judgment.

Effort bound. A cap on concurrent subagents, and a warning that many subagents with long results fill the main context. No public rule on how much work to do before reporting.

Human involvement. Subagents cannot ask the person: the question tool is removed from every subagent, even when listed. Only the main agent talks to the person. Permission prompts from subagents are passed up to the main session, named by the subagent that raised them. Whether to ask a clarifying question is left to the model; nothing public states a rule.

Source (fetched): https://code.claude.com/docs/en/sub-agents , https://code.claude.com/docs/en/common-workflows

---

## 2. Google

### 2a. AI co-scientist

Mechanism. Specialised agents generate, review, rank and evolve research hypotheses. A Ranking agent runs a tournament. Each new hypothesis enters at Elo 1200. Pairs are compared by an LLM judge; top-ranked pairs get multi-turn simulated debates, lower-ranked pairs a single-turn comparison. A Proximity agent builds a similarity graph, and matches favour pairing similar hypotheses, newer ones, and higher-ranked ones. A Supervisor agent keeps a task queue, periodically computes statistics (how many hypotheses wait for review, tournament progress, whether new generation or evolving existing ideas is paying off more), and from these sets the weights with which each agent type is sampled for the next task.

Global ranking or local. Global. The Elo rating puts every hypothesis on one scale, whatever its origin. This is the only system in this survey that does this.

Effort bound. Effort is split between agent types by the Supervisor's weights, which shift toward whatever has been paying off. The system runs continuously; the Supervisor decides when a terminal state is reached, but the paper does not state the test.

Human involvement. Scientists can change the goal, write reviews, add their own hypotheses to the tournament, and point the system at a direction, at any time. The system does not ask them anything. Involvement is started by the person.

Source (fetched): Gottweis et al., "Towards an AI co-scientist", 2025. https://arxiv.org/abs/2502.18864 , full text https://arxiv.org/html/2502.18864v1

### 2b. AlphaEvolve (and FunSearch, its predecessor)

Mechanism. An LLM proposes edits to programs. Every program is stored with its scores in a program database. Prompts are built from programs sampled from the database. The database is inspired by MAP-Elites (keep the best program in each cell of a grid of features) and an island model (separate subpopulations). New programs pass an evaluation cascade: small, cheap tests first, harder ones only if earlier ones pass.

In FunSearch, whose code is public, the rule is concrete. Pick an island uniformly at random. Within it, group programs by their score signature and sample a group by a softmax over scores, with a temperature that decays and then resets periodically. Within a group, prefer shorter programs. Periodically, wipe the worse half of the islands and reseed each from the best program of a surviving island. AlphaEvolve's paper does not publish its exact sampling rule.

Global ranking or local. Global within an island: one scalar score orders all programs. Islands keep diversity by preventing one ranking from taking over.

Effort bound. Fixed by the run's compute. The cascade bounds effort per candidate: a bad one is dropped after the cheap tests.

Human involvement. The person supplies the starting program, the scoring function, and optional context in the prompt, before the run. Nothing during the run.

Sources (fetched): Novikov et al., "AlphaEvolve", 2025. https://arxiv.org/abs/2506.13131 , full text https://arxiv.org/html/2506.13131 . FunSearch code: https://github.com/google-deepmind/funsearch/blob/main/implementation/programs_database.py

---

## 3. Tree search over LLM steps

### 3a. Sakana AI Scientist v2 (agentic tree search)

Mechanism. Each node is an experiment script and its result. Nodes are buggy (the script failed or its plot failed a vision-model check) or non-buggy. Each step expands several nodes in parallel. With a set probability a buggy node is picked to debug; otherwise a non-buggy node is picked best-first, where an LLM rates candidates on their metrics, training curves and plot quality. The search runs in four stages (prototype, hyperparameter tuning, the research agenda, ablations), each with its own exit test and node allotment.

Global ranking or local. Global within a stage, by the LLM's rating, but the ratings are produced for the candidates of that step, so I am not sure they are comparable across steps.

Effort bound. Hand-set: about 21 nodes for the first stage and 12 for each later one, at most 3 debug attempts in a row, one hour per node, 15 hours per paper. Stages end on a test ("a working prototype ran", "training curves converged on at least two datasets") or when their budget is spent. The paper's text and its parameter table disagree on the debug probability.

Human involvement. None during the run.

Source (fetched): Yamada et al., "The AI Scientist-v2", 2025. https://arxiv.org/abs/2504.08066 , full text https://arxiv.org/html/2504.08066

### 3b. Tree of Thoughts and LATS

Covered in the earlier survey (A4). In short: Tree of Thoughts keeps the best few nodes per level by an LLM score; LATS runs Monte Carlo tree search with an LLM value and self-reflection. Global queue in LATS (by UCT score), local per level in Tree of Thoughts. Effort is a fixed number of expansions. No human.

Sources (fetched in the earlier survey): https://arxiv.org/abs/2305.10601 , https://arxiv.org/abs/2310.04406

### 3c. Reflexion

Mechanism. The agent tries a task, gets a signal (task success, unit tests), writes a short reflection on what went wrong, and keeps it in memory for the next try.

Global ranking or local. Neither; it repeats one task.

Effort bound. A fixed maximum number of tries, stopping early on success, and a memory capped at a few reflections (from memory: one to three). The abstract confirms the memory buffer but not its size.

Human involvement. None.

Source (fetched abstract; budget details from memory): Shinn et al., 2023. https://arxiv.org/abs/2303.11366

---

## 4. OpenAI and coding agents

### 4a. OpenAI Deep Research

Mechanism. Before research starts, the system may ask clarifying questions about the person's goals, or in some surfaces show a research plan for the person to edit. Then it runs alone to the end. Secondary reports say a smaller helper model does the clarifying and rewrites the request; OpenAI has not documented that. The clarifying step is not in the API; developers build their own.

Global ranking or local. Nothing public.

Effort bound. Nothing public on how it decides how long to work.

Human involvement. Questions once, at the start, all together. None afterwards.

Source (fetched via search results; the launch page refused the fetch): OpenAI help center, https://help.openai.com/en/articles/10500283-deep-research-faq ; launch post https://openai.com/index/introducing-deep-research/ (not fetched).

### 4b. OpenAI Agents SDK (and Swarm before it)

Mechanism. A handoff to another agent is a tool the model calls, such as `transfer_to_refund_agent`. The model picks among the handoffs it is given, steered by each one's description. For approvals, a tool can declare `needs_approval`, either always or through a function the developer writes that decides per call.

Global ranking or local. Local. The model picks the next agent.

Effort bound. A maximum number of turns per run (from memory).

Human involvement. The developer places approval rules on tools. When a run hits them, it pauses and returns a list of pending approvals. The person can approve or reject some and leave others; the resolved ones go ahead and the rest pause again. A decision can be made sticky for the rest of the run ("always approve this tool"). If the arguments cannot be inspected, the rule fails closed and asks.

Sources (fetched): https://openai.github.io/openai-agents-python/handoffs/ , https://openai.github.io/openai-agents-python/human_in_the_loop/

### 4c. OpenHands

Mechanism. Each action carries a risk level (low, medium, high, unknown), set by the LLM itself or by a separate analyzer. A confirmation policy maps the risk level to "ask the user first" or "go ahead": always confirm, or confirm only at or above a risk threshold. Unknown risk is treated as needing a check.

Global ranking or local. Not addressed.

Effort bound. A maximum number of iterations per task (from memory).

Human involvement. A threshold on one per-action number. This is a one-threshold version of Horvitz's rule, with risk in place of the cost of a wrong guess.

Source (found by search, not fetched in full): https://docs.openhands.dev/sdk/arch/security.md

### 4d. Devin

Mechanism. "Interactive planning": at the start of a session Devin searches the codebase, lists relevant files and findings, and lists its open questions, then drafts a detailed plan. By default it waits thirty seconds for the person and then goes ahead with its plan.

Global ranking or local. Nothing public.

Effort bound. Nothing public.

Human involvement. Questions batched at the start. If the person does not answer, Devin proceeds on its own answers. This is answering by proxy with a timeout.

Source (fetched via search results): https://docs.devin.ai/work-with-devin/interactive-planning

### 4e. SWE-agent

From memory: a single agent with a fixed per-task cost cap. No planning over a set of items and no asking. Nothing to copy for our three problems.

Source (not fetched): https://github.com/SWE-agent/SWE-agent

---

## 5. Multi-agent frameworks

### 5a. LangGraph

Mechanism. A node calls `interrupt(payload)`. The graph saves its state and returns the payload to the caller. The caller resumes with `Command(resume=value)`, and that value becomes the return of `interrupt()`. Common uses: approve or reject an action, edit state, review a tool call.

Global ranking or local. Not addressed.

Effort bound. A recursion limit on steps (from memory).

Human involvement. The developer decides where interrupts go; the model does not. Several parallel branches can each interrupt. All pending interrupts are listed with IDs, and the caller can resume them together in one call by passing a map from ID to answer. This is batching built into the framework.

Source (fetched): https://docs.langchain.com/oss/python/langgraph/interrupts

### 5b. AutoGen / AG2 SelectorGroupChat

Mechanism. An LLM reads the conversation history and each participant's name and description, and names the next speaker. A developer function can override the choice, or narrow the candidates the LLM chooses from. By default the same agent cannot speak twice in a row.

Global ranking or local. Local. One choice of next speaker per turn.

Effort bound. Termination conditions checked after each turn, such as a keyword or a maximum message count.

Human involvement. The person is a participant (`UserProxyAgent`). The developer routes to the person at set points, for example after the planner speaks; "APPROVE" lets the work go on.

Source (fetched): https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/selector-group-chat.html

### 5c. CrewAI hierarchical process

Mechanism. A manager agent assigns tasks to crew members by role and tools, and checks their outputs. The docs give no rule for ordering or checking.

Global ranking or local. Local, inside the manager's prompt.

Effort bound. Not described.

Human involvement. Not on the hierarchical-process page. Tasks have a `human_input` flag that asks the person to review that task's output (from memory).

Source (fetched): https://docs.crewai.com/en/learn/hierarchical-process

### 5d. MetaGPT

From memory: roles (product manager, architect, engineer, tester) follow a fixed standard procedure, each passing a document to the next. The order is fixed by the procedure, not chosen. No ranking and no asking during a run.

Source (not fetched): Hong et al., "MetaGPT", ICLR 2024. https://arxiv.org/abs/2308.00352

---

## 6. When to ask the human: research methods

### 6a. KnowNo (robots that ask for help)

Mechanism. The LLM planner gives a confidence for each candidate next step. On a calibration set of labelled cases (400 in the paper), compute how unconfident the model was in the right answer, and take a quantile of that as a threshold. At run time, keep every candidate whose confidence clears the threshold. If one candidate is left, act. If more than one is left, ask the person to choose among them. One knob, the target error rate, sets how often it asks: a lower target asks more.

Global ranking or local. Local, per decision.

Effort bound. Not addressed.

Human involvement. This is the only method found with a guarantee: with high probability over the calibration set, the rate of task success on new cases is at least the target. It extends to multi-step plans. It assumes the person answers faithfully. The question it asks is a short multiple choice, not an open question.

Source (fetched): Ren et al., "Robots That Ask For Help", CoRL 2023. https://arxiv.org/abs/2307.01928 , full text https://arxiv.org/html/2307.01928

### 6b. Clarify when necessary (intent-sim)

Mechanism. Sample several possible readings of the person's intent, and measure how spread out they are (their entropy). Ask when the spread is high. With a fixed small budget of questions, this picks better cases to clarify than other uncertainty measures, about doubling the gain over picking at random.

Global ranking or local. It ranks cases by spread, so it can rank all candidate questions on one scale.

Human involvement. Asks the cases with the highest spread, up to a budget.

Source (fetched abstract): Zhang and Choi, 2023. https://arxiv.org/abs/2311.09469 . Related: Kuhn, Gal, Farquhar, "CLAM", 2022, which also used a simulated user given the hidden answer to test clarification automatically. https://arxiv.org/abs/2212.07769

### 6c. Underspecified coding tasks (Ambig-SWE and follow-ups)

Mechanism. SWE-bench issues are stripped of details. A simulated user who has the full issue answers the agent's questions. The findings: models are poor at telling a clear task from an unclear one; they tend to guess rather than ask; when they do ask, results improve a lot. A 2026 follow-up ("Ask or Assume?") splits the job: one agent detects missing information, another writes code. It asks less on simple tasks and more on complex ones.

Human involvement. The useful parts for us are the split between detecting and doing, and the simulated user who holds the hidden answer, which is how our proxy is tested.

Sources (fetched abstracts): Vijayvargiya et al., "Interactive Agents to Overcome Ambiguity in Software Engineering", 2025. https://arxiv.org/abs/2502.13069 . "Ask or Assume?", 2026. https://arxiv.org/abs/2603.26233

---

## Recommendation

### (1) Priority over items anywhere in the tree

What recent systems do. Best-first by an LLM score (AI Scientist v2, LATS), or sampling by a softmax over scores (FunSearch). Only the co-scientist makes scores comparable across the whole pool, by pairwise comparison and Elo. All of them score states (how good a node is). None score work items (how much one more call would change the plan).

Copy. Keep value of computation as the key of the global queue (earlier A1, A4). Feed it with the co-scientist's tournament. Rate nodes by pairwise LLM comparisons and keep an Elo rating per node. This fixes the problem the earlier survey flagged: a direct rater may not give scores comparable across depths, but a pairwise judge does. The rating is the node's value. The number of comparisons it has had is its uncertainty. Those are the two inputs value of computation needs. Copy also the co-scientist's match choice: compare similar nodes, and spend more comparisons on new and high-rated ones.

If the first version must be simpler, take AI Scientist v2's rule: best-first by rating, with a fixed chance of picking a node that needs repair. Move to value of computation when the ratings exist.

### (2) How much work before the next round

What recent systems do. Hand-set budgets only. Anthropic's table of effort by complexity class, AI Scientist v2's node counts and exit tests per stage, cost and message caps. Nobody stops on value.

Copy. Use a hand-set cap per round, scaled by a complexity class the planner assigns to the round, as Anthropic does. Inside the cap, stop early by the earlier survey's rule: when no candidate's value of computation, times survival, clears a floor. Add AI Scientist v2's idea of an exit test per phase where one exists, for example "every open node has been rated at least once". The cap guards against the known failure (spending far too much on simple work). The floor is the part no recent system has.

### (3) What to put in front of the person, and when

What recent systems do. Three patterns. Ask once at the start, all questions together, then work alone (Deep Research, Devin; Devin proceeds on its own answer after a timeout). Pause at points the developer placed, with several pending questions answered in one pass (LangGraph, OpenAI Agents SDK). Gate by a threshold on one per-action number (OpenHands risk level). Only the coordinating agent talks to the person (Claude Code). The co-scientist never asks; the person steps in at will.

Copy.
- Keep Horvitz's thresholds as the frame (earlier A5): answer by proxy above the upper line, ask between the lines, wait below.
- Set the proxy line by KnowNo's calibration instead of by hand. Log each case where the Director confirmed or overrode the proxy. From that log take the threshold. At run time, if only one answer clears it, the proxy answers. If several do, the node goes to the Director as a short choice among them. This is the earlier survey's "learn from the log" (A8) done with a guarantee and one knob.
- Rank the nodes that go to the Director by the spread of the proxy's answers (intent-sim) times the work built on them (earlier A7).
- Batch by the earlier rule (A6): release a round when the summed waiting cost of queued nodes exceeds the cost of one review. Copy the mechanics from LangGraph and the Agents SDK: questions wait in one pending list with IDs, the Director answers any subset, unanswered ones stay pending, answered ones release their work.
- Copy Devin's default: if the Director does not answer a node, work continues on the proxy's answer, which is the earlier survey's pondering (B1).
- Only the coordinator puts questions to the Director, as in Claude Code. Worker agents raise candidates; they never ask.

What would prove this wrong. If pairwise ratings of our nodes turn out unstable (the same pair judged both ways on repeat), the Elo input fails and we fall back to a direct rater. If the Director's answers do not repeat across similar nodes, the calibration log cannot set a threshold, and the proxy line stays hand-set.
