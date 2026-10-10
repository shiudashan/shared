# Survey: allocating attention, and working ahead

Purpose: find prior work to copy for two questions. A: how to spend effort and the Director's attention across the whole tree. B: how to work during the Director's turn so the work is kept when the guess holds and is cheap to drop when it does not.

Words used below.
- "Computation" means one agent call: expand a node, revise a node, or develop a leaf.
- "Survival" means the chance that the Director's next feedback does not invalidate that work.
- "Proxy" means the simulated Director.

Sources marked "fetched" were read in this survey. Sources marked "not fetched" are standard results I state from memory; check them before relying on the detail.

---

## Question A: allocating attention

### A1. Value of computation (rational metareasoning)

What it is. Russell and Wefald treat each computation as an action. Its value is the expected improvement in the final decision that it would bring, minus its cost. Hay, Russell, Tolpin and Shimony give this a precise form. The state is what has been computed so far. Each step either runs one more computation (paying a fixed cost) or stops and takes the option with the best current estimate.

Rule to copy.
- Score every candidate computation anywhere in the tree by its value of computation (VOC): expected gain in the final plan if we run it, minus its cost. Run the highest score next. All nodes are comparable because all scores are in the same unit.
- Stop when no candidate has a score above its cost. This is the budget rule for "how much work before the next round."
- Use the "myopic" estimate (look one computation ahead) to start. The paper proves that when the myopic rule says compute, the optimal rule also computes. Its known flaw is that it stops too early.
- If the myopic rule stops too early, use the "blinkered" estimate: score a node by the best result of spending several computations on that node alone, while holding every other node at its current estimate. Its cost does not grow with the number of nodes.
- The paper also proves that the expected number of computations is bounded by the value of perfect information divided by the cost per computation. That gives a ceiling on the budget per round.

What we must produce.
- A current value estimate per node, with uncertainty (how much one more call could move it).
- A cost per computation. For us this is tokens, which is time at about 50 tokens/s.
- For our waste goal: multiply the gain by survival. Work the Director is likely to overturn is worth little now.

Source (fetched): Hay, Russell, Tolpin, Shimony, "Selecting Computations: Theory and Applications", UAI 2012. https://arxiv.org/abs/1207.5879 (read via https://ar5iv.labs.arxiv.org/html/1207.5879).
Background (not fetched): Russell and Wefald, "Do the Right Thing", MIT Press 1991.

### A2. Learning to select computations (BMPS)

What it is. Callaway, Lieder, Griffiths and others approximate the value of a computation as a weighted mix of three easy features: the myopic value, the value of perfect information about one option, and the value of perfect information about everything. They fit the weights.

Rule to copy. VOC(c) is approximately w1 times myopic value, plus w2 times value of perfect information on c's node, plus w3 times value of perfect information on the whole tree, minus cost. Pick the largest. Stop when none is positive. The key fact: the true value always lies between the myopic value and the value of perfect information.

What we must produce. The same per-node value estimates as A1, plus a few logged runs to fit three weights.

Source (fetched abstract): Callaway et al., "Learning to Select Computations", UAI 2018. https://arxiv.org/abs/1711.06892

### A3. VOI-aware tree search (MCTS with value of information at the root)

What it is. Tolpin and Shimony replace the usual UCT choice at the root of a search tree with a value-of-information estimate. The point is that only the final choice earns reward, so the search should cut "simple regret" (how good the final pick is), not total regret.

Rule to copy. For the current best option, the value of sampling it more is roughly (remaining budget / samples so far) times the second-best value times exp(-1.37 times squared gap times samples so far). For any other option, the same form with the gap to the best. Sample the option with the largest estimate. Below the root they keep plain UCT.

What we must produce. A value estimate per option and a count of how much work it has had. The formula assumes values in 0 to 1 and repeated noisy samples; our agent calls are not repeated samples of the same thing, so I am not sure the formula transfers. The idea transfers: spend effort where the gap between rival options is small and evidence is thin.

Source (fetched): Tolpin and Shimony, "VOI-aware MCTS", 2012. https://arxiv.org/abs/1207.5589 ; companion "MCTS Based on Simple Regret", AAAI 2012. https://arxiv.org/abs/1207.5536

### A4. Best-first search over a global frontier (A*, Tree of Thoughts, LATS)

What it is. One priority queue holds every open node in the tree. Each step pops the best one. A* orders by cost so far plus estimated cost to go. Tree of Thoughts has an LLM propose children and an LLM evaluator score them, then keeps the best few per level (BFS) or goes deep and prunes below a threshold (DFS). LATS runs Monte Carlo tree search with an LLM value function and LLM self-reflection.

Rule to copy. A single global queue keyed by one score. The score comes from an LLM evaluator that rates a node (as a number, or as "sure / maybe / impossible"). Prune below a threshold.

What we must produce. An evaluator prompt that returns a comparable score for any node. Our rater could serve, if its scores are comparable across nodes at different depths.

Note. These systems have no human in the loop and no notion of waste from later feedback. They give us the queue, not the key. A1 gives the key.

Sources (fetched abstracts): Yao et al., "Tree of Thoughts", 2023. https://arxiv.org/abs/2305.10601 . Zhou et al., "Language Agent Tree Search", ICML 2024. https://arxiv.org/abs/2310.04406 , code https://github.com/lapisrocks/LanguageAgentTreeSearch . A* (not fetched): Hart, Nilsson, Raphael 1968.

### A5. Mixed-initiative thresholds: act, ask, or do nothing (Horvitz)

What it is. Horvitz lists twelve principles for systems that act on a user's behalf. The core is a decision rule. Given the probability that the user wants a thing, compare the expected utility of acting, of asking (dialog), and of doing nothing. The lines cross at threshold probabilities.

Rule to copy.
- Let p be the probability that the Director would accept the proxy's answer on this node.
- Assess six utilities: act when right, act when wrong, ask when right, ask when wrong, skip when right, skip when wrong.
- Two thresholds fall out. Above the upper threshold, answer by proxy. Between the two, ask the Director. Below the lower one, do nothing yet.
- Context moves the thresholds. If a wrong proxy answer is costly (much downstream work would be built on it), the proxy threshold rises. If the Director is busy, asking costs more, so the asking band narrows.
- The paper says the thresholds can be set directly by the designer or user instead of computing utilities. LookOut let users set the two thresholds by hand.
- Other principles that apply to us: minimize the cost of poor guesses (easy to undo); scope the precision of the service to the uncertainty; let the user invoke and dismiss cheaply.

What we must produce. p per node: the proxy's confidence that the Director agrees. Plus two thresholds, which we can set by hand to start.

Source (fetched, full text): Horvitz, "Principles of Mixed-Initiative User Interfaces", CHI 1999. https://www.erichorvitz.com/chi99horvitz.pdf

### A6. Attention-sensitive alerting: when and how much to put in front of the person

What it is. Horvitz, Jacobs and Hovel decide whether to interrupt a user now or defer. They weigh the expected cost of interrupting (depends on the user's attention state) against the cost of delay (each item loses value at a rate set by how critical it is).

Rule to copy.
- Each pending item has a rate of loss while it waits. Call it its criticality. For us: how much work is blocked or at risk while this node waits for the Director.
- Net value of alerting = value of showing the item now minus expected cost of the interruption. Alert only when positive.
- Batch: show n items together. Net value = sum of each item's value minus the cost of one interruption of size n. Bundling raises the value per interruption. This answers "which nodes go in front of the person, and when": collect items until their summed value exceeds the cost of one review round.

What we must produce. Per node, a rate of loss while waiting (how much downstream work depends on it). A cost per review round, rising with the number of items.

Source (fetched, full text): Horvitz, Jacobs, Hovel, "Attention-Sensitive Alerting", UAI 1999. https://arxiv.org/abs/1301.6707

### A7. Value of information for choosing which question to ask

What it is. Chajewska, Koller and Parr keep a belief over the person's preferences. They ask the question with the highest value of information for the current decision. They stop when the expected loss from deciding now falls below a set threshold. Handa et al. (OPEN) do the same with an LLM turning abstract queries into natural-language questions.

Rule to copy. Among nodes that could go to the Director, rank by how much the Director's answer would change what we do next (expected change in downstream work), not by how unsure we are. Stop asking when the expected loss from proceeding on the proxy's guess is below a threshold.

What we must produce. For each candidate question, the work it would change if answered one way versus another. In our tree this is roughly survival times the size of the subtree built on that node.

Sources: Chajewska, Koller, Parr, "Making Rational Decisions Using Adaptive Utility Elicitation", AAAI 2000 (fetched summary). https://faculty.cc.gatech.edu/~isbell/reading/papers/Chajewska-AAAI00.pdf . Handa et al., "Bayesian Preference Elicitation with Language Models", 2024 (fetched abstract). https://arxiv.org/abs/2403.05534

### A8. Learning to defer and the reject option

What it is. A model either answers or hands the case to a human expert. Chow's reject rule: answer only when the best answer's confidence exceeds one minus the cost of rejecting. Mozannar and Sontag learn a classifier and a "rejector" jointly from records of the expert's decisions.

Rule to copy. Proxy answers when its confidence of matching the Director exceeds a threshold set by the cost of asking. This is A5 with fewer terms. The learning part: log every case where the Director overrode or confirmed the proxy, and use that log to calibrate the proxy's confidence.

What we must produce. A record of proxy guesses and the Director's actual answers.

Sources: Mozannar and Sontag, "Consistent Estimators for Learning to Defer to an Expert", ICML 2020 (fetched abstract). https://arxiv.org/abs/2006.01862 . Chow, "On Optimum Recognition Error and Reject Tradeoff", IEEE Trans. Inf. Theory 1970 (not fetched; rule taken from secondary sources).

### A9. LLM research agents with a human steering (Co-STORM)

What it is. Several LLM agents hold a discussion. The user watches and steps in when they choose. A moderator agent raises questions on the user's behalf. A dynamic mind map (a tree) organizes what has been found.

Rule to copy. Not a scheduling rule. The useful idea is that the human steers by intervening at will, while the agents keep going by default. The system does not wait for the human.

Source (fetched abstract): Jiang et al., "Into the Unknown Unknowns", EMNLP 2024. https://arxiv.org/abs/2408.15232 , code https://github.com/stanford-oval/storm

### Recommendation for A

Copy two things first.

1. Value of computation with the myopic estimate (A1), as the single key of one global queue (A4). Score each candidate call by expected gain in the plan times survival, divided by tokens. Run the best. End the round's budget when the best score falls below a set floor. Why: it answers both "where next" and "how much before feedback" with one number, and the stopping rule comes with it.

2. Horvitz's thresholds for proxy versus ask (A5), with alert batching (A6) for when to hand a set to the Director. Why: it needs only one new estimate, the proxy's confidence per node, and two hand-set thresholds. The batching rule turns "when to ask" into "when the summed waiting cost of the queued items exceeds the cost of one review".

Both need the same two new inputs: a comparable value per node, and the proxy's confidence that the Director agrees. Survival is one minus the chance of a disagreement.

---

## Question B: working ahead during the person's turn

### B1. Game-tree pondering (thinking on the opponent's time)

What it is. A chess engine uses the opponent's thinking time. It guesses the opponent's reply (the second move of its own best line) and searches the resulting position. On a hit it can move at once or keep searching. On a miss it undoes the guess and restarts. Work stored in the transposition table (a cache of evaluated positions) can still help after a miss.

Rule to copy. During the Director's turn, take the proxy's predicted answer for the nodes under review and work on the tree as if those answers were given. On a hit, the work is already done. On a miss, drop the dependent work but keep anything cached that does not depend on the guessed answer.

Why it fits us. The opponent's time is time the engine would otherwise not use. Our server is idle while the Director reads. Speculation in that window does not compete with confirmed work. The other methods in this list assume spare parallel capacity; pondering assumes idle time, which is our situation.

What we must produce. The proxy's predicted answer per node in the review. A cache of agent results keyed by their inputs, so a miss does not throw away work whose inputs did not change.

Source (fetched): Chess Programming Wiki, "Pondering". https://www.chessprogramming.org/Pondering . The wiki cites Robert Hyatt that the prediction is right about half the time.

### B2. Optimistic concurrency control (read, validate, write)

What it is. Kung and Robinson let transactions run without locks. Each transaction reads freely and writes to private storage. At commit it is validated: if nothing it read was changed by a transaction that committed meanwhile, its writes are made visible. Otherwise it is restarted.

Rule to copy. Every speculative agent call records its "read set": the nodes and Director answers it was given. When the Director's feedback arrives, check each speculative result: if none of its read set changed, commit it. If any did, discard it and requeue. This is the keep or squash test, and it is exact.

What we must produce. The read set of each call. Our agents already get their files in the message, so the read set is the list of files sent.

Source (fetched summary of the paper): Kung and Robinson, "On Optimistic Methods for Concurrency Control", ACM TODS 1981. https://www.eecs.harvard.edu/~htk/publication/1981-tods-kung-robinson.pdf

### B3. Speculative Actions (LLM agents)

What it is. A slow "actor" decides the next action. Meanwhile a fast "speculator" guesses it, and the system launches the follow-on call for each of the top few guesses. If the actor's action matches a guess, that branch is already running. If not, the guesses are dropped and the system proceeds as normal. The result is the same as without speculation, only faster.

Rule to copy.
- Guess the top k next outcomes. Pre-launch the follow-on work for each. Commit the branch that matches. Drop the rest.
- Speculate only on work with no visible side effects, or work that can be undone.
- The paper gives a cost-latency formula: with hit probability p, the long-run saving is about p/(1+p) of the overlap. Larger k raises hit rate and cost together.

What we must produce. A cheap predictor of the Director's answer (the proxy), a match test between predicted and actual answer, and a rule that speculative writes stay out of the shared tree until committed.

Source (fetched): Ye et al., "Speculative Actions: A Lossless Framework for Faster Agentic Systems", 2025, ICLR 2026. https://arxiv.org/abs/2510.04371

### B4. Interactive Speculative Planning (human in the loop)

What it is. A fast agent drafts plan steps ahead. A slow agent checks each step asynchronously, using the draft as a provisional prefix. A human can interrupt a slow step or type in their own step. Lookahead is capped at k steps (k = 4 in their runs).

Rule to copy.
- Cap how far speculation runs ahead of confirmed work.
- On a mismatch at step i, cancel every running call whose prefix includes the wrong step i. Keep everything before i.
- Show the person results in dependency order, never anything built on an unconfirmed prefix.
- Let the person override at any time; their input replaces the step and only the work that depended on the old step is dropped.

What we must produce. Dependency order between nodes (which work was built on which), and a cap on speculative depth.

Source (fetched): Hua et al., "Interactive Speculative Planning", ICLR 2025. https://arxiv.org/abs/2410.00079

### B5. Dynamic Speculative Planning (learned lookahead depth)

What it is. Same as B4, but the lookahead k is predicted per step from the trajectory so far. The predictor learns online from how many speculative steps turned out correct. One knob sets the tradeoff between speed and cost.

Rule to copy. Set speculative depth per node from a record of how often past speculation on similar nodes was kept. Start with a fixed depth and a knob; learn later.

What we must produce. A log of speculative depth tried versus depth kept.

Source (fetched): Guan et al., "Dynamic Speculative Agent Planning", ICLR 2026. https://arxiv.org/abs/2509.01920 , code https://github.com/guanyilin428/Dynamic-Speculative-Planning

### B6. Branch confidence and pipeline gating

What it is. A processor attaches a confidence to each branch prediction. Mispredictions concentrate in a small set of low-confidence branches. Pipeline gating stops fetching past low-confidence branches to avoid wasted work. Eager execution runs both paths of a low-confidence branch.

Rule to copy. Speculate past a Director decision only when the proxy is confident. When it is not, either wait (gating) or, if both answers are cheap to develop, work both (eager). This is the speculative counterpart of A5's thresholds and uses the same confidence.

What we must produce. The proxy's confidence per node, already needed for A5.

Source (fetched pointer, not full text): Jacobsen, Rotenberg, Smith, "Assigning Confidence to Conditional Branch Predictions", MICRO 1996. https://ericrotenberg.wordpress.ncsu.edu/files/2025/06/paper_MICRO-29_jrs.pdf . Pipeline gating is Manne, Klauser, Grunwald, ISCA 1998 (not fetched).

### B7. Speculative decoding (analogy only)

What it is. A small model drafts several tokens. The large model checks them all in one pass. Each draft token is accepted with a probability that keeps the output identical to the large model alone. The first rejection ends the run; a corrected token replaces it.

What it adds. The structure "draft many, verify in one pass, keep the longest accepted prefix". For us: the Director reviews a batch of proxy answers at once and confirms or corrects them; everything built on confirmed answers is kept. The exact acceptance math does not transfer.

Source (fetched abstract): Leviathan, Kalman, Matias, "Fast Inference from Transformers via Speculative Decoding", ICML 2023. https://arxiv.org/abs/2211.17192

### B8. Anytime algorithms

What it is. An anytime algorithm can be stopped at any time and returns its best result so far, improving with time. A performance profile records quality versus time. A monitor decides when to stop.

Rule to copy. Order speculative work so the most useful part finishes first, so that when the Director returns we can stop at once and lose little. The profile also feeds A1's stopping rule.

What we must produce. Rough quality versus time for each kind of call.

Sources (fetched abstracts): Zilberstein, "Using Anytime Algorithms in Intelligent Systems", AI Magazine 1996. https://doi.org/10.1609/aimag.v17i3.1232 . Hansen and Zilberstein, "Monitoring and Control of Anytime Algorithms: A Dynamic Programming Approach", Artificial Intelligence 2001.

### Recommendation for B

Copy two things first.

1. Pondering (B1) as the policy: during the Director's turn, the proxy predicts the Director's answers and the system works the tree as if they were given. Why: the server is otherwise idle then, so speculation costs no confirmed work. Gate it by the proxy's confidence (B6), the same number A5 uses.

2. Optimistic concurrency control (B2) as the keep or squash test: each speculative call records what it read; on feedback, commit results whose reads did not change and requeue the rest. Use Interactive Speculative Planning's rule (B4) for the cascade: a rejected answer cancels only the work built on it. Why: the test is exact and needs only the list of files each agent was sent, which we already have.

Speculative Actions (B3) is the closest LLM-agent paper and confirms the scheme works, but it assumes spare parallel capacity. Our capacity is fixed, so it applies only to the idle window, which is B1.
