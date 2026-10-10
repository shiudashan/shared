# Survey for f5: speed, context control, guardrails

## Answer

Most of f's time is the model thinking. Cut that first.

In the i1 run with the simulated Director, the Qwen box did about 4,580 seconds of work by the
cost model, and the run took 4,800 seconds of wall time. So the Qwen box is the bottleneck, and
every token saved on it shortens the run almost one for one.

Where that work went:

- Decode was 184,000 output tokens, or about 3,680 s. Of these, 148,000 were thinking tokens,
  about 2,970 s. The rater alone thought 80,000 tokens, about 1,600 s.
- Prefill was 1.30 million uncached input tokens, about 890 s. Only 30% of Qwen input hit the
  prefix cache. The two librarian calls on Qwen sent 607,000 uncached tokens.
- The three librarian calls on GLM sent 3.7 million input tokens with zero reported cache hits.

The top five changes, by expected saving on that run:

1. Switch thinking off for the rater and cap it for the expander, with vLLM's per-request
   thinking budget. About −2,100 s, or −45%.
2. Make the prompt prefix stable, and mask old tool results in large rare batches instead of
   one at a time. About −640 s, or −14%.
3. Speculative decoding (Qwen's built-in multi-token prediction, or suffix decoding). About
   −350 to −670 s on the decode left after item 1. I am not sure of the acceptance rate at 14
   concurrent requests; it must be measured.
4. Constrained decoding for the rater's and expander's answers: shorter answers, no retries,
   no judgments of nodes it was not asked about. About −400 s.
5. Fewer agent steps: batch the librarian's tool calls and writes. About −200 s on Qwen, and
   most of the GLM input.

Together these bring the i1 run from about 80 minutes to about 25–30 minutes, if quality holds.
What would prove this wrong: a re-run where the token counts drop as predicted but wall time
does not, which would mean the box was not the bottleneck.

How the estimates are made. Time ≈ uncached input tokens / 1,460 tok/s + output tokens /
50 tok/s, both aggregate over the box. Token counts are the sums over
`reports/profile-e2e-i1-sim.txt`. Savings are against that run. GLM has no cost model yet, so
GLM savings are given in tokens only.

---

## 1. Speed, ordered by expected gain for us

### S1. Per-role thinking budget (vLLM `thinking_token_budget`)

Link: https://docs.vllm.ai/en/latest/features/reasoning_outputs/ . vLLM, 93k stars, pushed daily.

vLLM takes a per-request `thinking_token_budget` sampling parameter. When the budget runs out it
forces the end-of-thinking string set in the server's `--reasoning-config`. We already pass
`chat_template_kwargs: {enable_thinking: false}` for roles marked `thinking: false`. Import:
thinking off for the rater and the simulated Director, a budget of about 1,000 tokens for the
expander, and no change for the librarian. Rating a set of siblings is a comparison, not a
derivation; it should not need 3,200 thinking tokens. Check the budget is enforced on our model:
an SGLang issue reports it ignored for Qwen3.6, and a vLLM forum thread reports a version that
ignored it when passed through `extra_args`.

Background, if a fixed budget hurts quality: DEER (Dynamic Early Exit in Reasoning Models,
arXiv 2504.15895) stops thinking when a trial answer is confident, training-free, and cut
thinking 19–80% across eleven models. Thinkless (NeurIPS 2025) and AdaptThink learn when to
think; they need training, so they are references, not imports.

Speed estimate. Rater thinking off: 79,900 tokens / 50 = −1,600 s. Expander capped at 1,000
per call (now about 1,800 on average over 32 calls): −26,000 tokens = −520 s. Total about
−2,100 s, −45% of the run.

### S2. Cache-stable prompt layout, and masking in batches

Links: Manus, "Context Engineering for AI Agents: Lessons from Building Manus" (July 2025),
https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus ;
Lumer et al., "Don't Break the Cache", arXiv 2601.06007 (Jan 2026); Anthropic context editing,
https://platform.claude.com/docs/en/build-with-claude/context-editing .

Manus calls the cache hit rate the most important metric of a production agent. Its rules: keep
the prefix byte-identical, only append, serialize deterministically, never change the tool list
mid-session. "Don't Break the Cache" measured the same across providers: keep dynamic content
at the end, and keep changing tool results out of the cached prefix. Anthropic's tool-result
clearing has a `clear_at_least` parameter for exactly this reason: every clear breaks the cache
from that point on, so clear a lot at once, rarely.

Our plugin `opencode/plugin/pin-prompt.ts` does the opposite. Once tool results pass 120,000
characters, it replaces the oldest result with a note on every step. Each step then changes
the context near its start, and the cache misses from there. Import: when the limit is passed,
mask down to well below it (for example to half), so the next many steps append to an
unchanged prefix. Also give each role a fixed prefix (system prompt, tools, seed) with the
per-call material after it. The rater got 1,600 cached tokens out of about 4,000, which
suggests something variable sits early in its prompt.

Speed estimate. Raising the Qwen hit rate from 30% to 80% of input cuts uncached prefill from
1.30 M to about 0.37 M tokens: −640 s, −14%. On GLM the 3.7 M librarian input tokens showed zero
cache hits; either the cache is off for GLM or it is not reported. That is the first thing to
check.

### S3. Speculative decoding: MTP, EAGLE-3, suffix decoding

Links: vLLM speculative decoding, https://docs.vllm.ai/en/stable/features/speculative_decoding/ ;
vLLM Qwen3-Next recipe, https://docs.vllm.ai/projects/recipes/en/latest/Qwen/Qwen3-Next.html ;
EAGLE, https://github.com/SafeAILab/EAGLE (2.5k stars); SpecForge (trains EAGLE-3 drafts),
https://github.com/sgl-project/SpecForge (1.2k stars, active); SuffixDecoding, NeurIPS 2025,
arXiv 2411.04975, in Arctic Inference https://github.com/snowflakedb/ArcticInference (488 stars,
active) and in vLLM as method `suffix`.

Our time is mostly decode, so this is the engine-side lever. The Qwen-Next family carries its
own multi-token-prediction head; vLLM turns it on with `--speculative-config` method
`qwen3_next_mtp`, 1–2 speculative tokens, no extra model. Suffix decoding needs no model: it
matches the recent tokens against a tree of past outputs. It suits our repetitive work, such as
the synthesizer's edits and the rater's fixed answer shape; the paper reports 1.8–4.5× on
SWE-bench agent traces. vLLM's docs say model-based methods (MTP, EAGLE) give the larger gains
and suffix the smaller, except on repetitive output. Import: turn on MTP, run
`vllm bench serve` at concurrency 14 with 0, 1, 2 speculative tokens, keep the best. Then try
suffix decoding as a second run.

Speed estimate. I am not sure of the gain at 14 concurrent requests; speculation pays less as
the batch grows. Assume 1.3–1.8× on decode. After S1, decode is about 1,600 s, so −350 to
−700 s. Without S1, −850 to −1,600 s.

### S4. Constrained decoding for answers (vLLM structured outputs, XGrammar-2)

Links: XGrammar, https://github.com/mlc-ai/xgrammar (1.9k stars, active); XGrammar-2 blog,
https://blog.mlc.ai/2026/05/04/xgrammar-2-fast-customizable-structured-generation , paper
arXiv 2601.04426; llguidance, https://github.com/guidance-ai/llguidance (884 stars, active).

XGrammar is vLLM's default structured-output backend. XGrammar-2 adds tag-triggered schemas
for tool calls and a reasoning channel, and reports near-zero latency overhead in vLLM. Import:
for the rater, a JSON schema whose node ids are an enum of exactly the nodes asked about, and
an answer that is the order only. For the expander, a schema where `relation` is the enum
`part | alternative`. The rater then cannot judge "root" when asked about t7, and the expander
cannot write `relation: undefined`. Both happened in the i1 run. Single-step roles with no
tools (the rater, the Director) can call vLLM's OpenAI endpoint directly with
`response_format`, so they skip the agent runtime.

Speed estimate. The rater's visible answers were 21,900 tokens, about 880 per call. A list of
ids is under 100: −19,000 tokens = −380 s. Each expander retry avoided saves about 60 s of box
work (17,600 in, 2,200 out). Total about −400 s, −9%.

### S5. Fewer steps: parallel and batched tool calls

Links: LLMCompiler, ICML 2024, https://github.com/SqueezeAILab/LLMCompiler (1.9k stars, not
maintained since 2024); opencode, https://github.com/anomalyco/opencode (212k stars, active).

Every agent step re-sends the whole context. One GLM librarian call took 36 steps for 42 tool
calls, 31 of them writes, and sent 1.9 M input tokens. LLMCompiler's idea is to plan the
independent calls and issue them together. opencode already accepts several tool calls in one
step. Import: tell the librarian to issue its searches and fetches in parallel, and to write
its reference files in one call (or give it a tool that writes several files). The idea is
what we import; LLMCompiler's code is old.

Speed estimate. Input grows with steps × context. Going from 36 steps to about 10 cuts that
call's input by about 70%, about 1.3 M GLM tokens. On Qwen, halving the librarian's 607,000
uncached tokens is −210 s.

### S6. Keeping caches alive, and program-aware scheduling

Links: Continuum, ICLR 2026, arXiv 2511.02230, https://github.com/Hanchenli/vllm-continuum (108
stars); KVFlow, NeurIPS 2025, arXiv 2507.07400; Autellix, arXiv 2502.13965; LMCache,
https://github.com/LMCache/LMCache (12k stars, active); SMG,
https://github.com/smg-project/smg (563 stars, active).

These keep an agent's prefix in memory while the agent waits on a tool (Continuum's time to
live), evict by when the agent will run next instead of least-recently-used (KVFlow, up to
1.8–2.2× against SGLang's hierarchical cache), spill prefixes to CPU memory instead of dropping
them (LMCache), and schedule by program instead of by request (Autellix, 4–15× program
throughput under load). SMG, which we run, already does cache-aware routing and priority
admission. Import: LMCache's CPU offload first, as it is a vLLM connector and no code of ours.
The research systems are forks of vLLM; read them, do not run them.

Speed estimate. Small for us today. The same expander prompt got 14,400 cached tokens on two
calls and 0 on a third, which is an eviction or a routing miss: about 10 s of prefill each
time. This matters more after S2 makes the cache worth keeping, and much more for the GLM
librarian with its long contexts.

### S7. Smaller models or cascades for easy roles

Links: RouteLLM, https://github.com/lm-sys/RouteLLM (5.6k stars, no commits since Aug 2024);
Arch-Router, arXiv 2506.16655, model katanemo/Arch-Router-1.5B, gateway
https://github.com/katanemo/plano (7k stars, active).

Routers pick a model per query. Our roles are fixed and known, so routing by role in
`roles.json` already does this job. A smaller model on the same box shares the same GPU, so it
saves less than turning thinking off on the model we have. Import nothing now.

Speed estimate. No gain beyond S1 on one box.

---

## 2. Context control

The finding across the agents below: most of them mask or summarize old tool results, a
sub-agent gets a fresh context and returns a short result, and plain masking is as good as an
LLM summary for half the cost.

### C1. opencode, which we run

Link: https://github.com/anomalyco/opencode ; source read at
`vendor/opencode/packages/opencode/src/session/compaction.ts` and `overflow.ts`.

opencode has two mechanisms. Compaction summarizes the session when tokens reach the usable
window (context minus a 20,000-token reserve). Prune erases the outputs of old tool calls,
keeping the newest 40,000 tokens of them, and only when it would free more than 20,000. Prune
only looks at messages before the last two user turns, so it never acts inside one long prompt,
which is how all our agents run. That is why our plugin masks on its own. Per-agent `steps`
caps the number of steps, and the `doom_loop` permission stops a third identical tool call.
Import: keep compaction off, and change our plugin's masking as in S2.

Speed: as S2.

### C2. Anthropic: context editing, memory tool, sub-agents, Claude Code

Links: https://platform.claude.com/docs/en/build-with-claude/context-editing ; "Effective context
engineering for AI agents" (Sep 2025),
https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents .

Tool-result clearing has `trigger`, `keep` (the last N tool results), `clear_at_least`, and
`exclude_tools`. Thinking-block clearing keeps the last N turns' thinking. Claude Code clears
old tool results first and summarizes the whole session only near the limit. Its sub-agents
start with a fresh context and hand back a summary. The essay's advice: keep references (paths,
URLs) and load the content just in time. Import: the parameters as the shape of our masking
rule; the exclude list for anything a later step must read (the librarian's own notes); drop
old thinking from the context, since a model that thinks again does not need to reread its old
thinking.

Speed: as S2. Dropping old thinking in multi-step calls also cuts input.

### C3. OpenAI Codex CLI

Link: https://github.com/openai/codex (128k stars, active).

Codex compacts at a token limit (`model_auto_compact_token_limit`, capped at 90% of the
window). After a compaction it keeps one summary plus up to 20,000 tokens of the recent user
messages, and drops old tool results. It also caps each tool output (`tool_output_token_limit`)
before it enters the history. Import: the per-tool output cap; our `clip` in the plugin does
this for repo reads, and webfetch should have one too.

Speed: each 10,000 tokens kept out of a 30-step librarian call saves up to 300,000 input tokens
if uncached.

### C4. OpenHands condenser

Links: https://docs.openhands.dev/sdk/arch/condenser ; blog (Apr 2025),
https://openhands.dev/blog/openhands-context-condensensation-for-more-efficient-ai-agents ;
https://github.com/OpenHands/OpenHands (90k stars, active).

When history exceeds a size, it keeps the first and the last events and replaces the middle with
an LLM summary. The blog reports up to 2× lower per-turn cost and flat response times in long
sessions. Import: the "keep first, keep last, cut the middle" rule. Not the LLM summary; see C5.

### C5. SWE-agent, mini-SWE-agent, and "The Complexity Trap"

Links: https://github.com/SWE-agent/SWE-agent (20k stars) and
https://github.com/SWE-agent/mini-swe-agent (8k stars), both active; Lindenbauer et al.,
NeurIPS 2025 workshop, arXiv 2508.21433, code
https://github.com/JetBrains-Research/the-complexity-trap .

SWE-agent replaces old observations with a one-line note and keeps the last few in full. The
JetBrains study compared this with LLM summarization across five models: masking halved cost
against the raw agent and matched or beat summarization. A hybrid saved another 7–11%. Import:
masking as our only mechanism, with a fixed window of recent tool results. No summarizer call.

Speed: about −50% input on long agent calls (the librarian). Added to S2, the masked prefix also
stays cached.

### C6. Aider repo map

Link: https://aider.chat/docs/repomap.html ; https://github.com/Aider-AI/aider (49k stars, last
push May 2026).

Aider sends a map of the repository, ranked by a graph of references and cut to a token budget,
instead of whole files. Import: the same for f's board. Give each agent a ranked outline of the
tree within a budget, and let it read nodes by path when it needs them.

Speed: depends on how much of the 17,500-token expander prompt is the tree. Not measured.

### C7. Goose

Link: https://goose-docs.ai/docs/guides/sessions/smart-context-management ;
https://github.com/aaif-goose/goose (55k stars, active).

Goose summarizes at 80% of the window (`GOOSE_AUTO_COMPACT_THRESHOLD`), with a fallback
strategy if still over. Same pattern as the others. Nothing new to import.

### C8. Manus: the file system as memory

Link: as S2.

Manus drops a web page's content from the context but keeps its URL, so the agent can fetch it
again. It writes a todo file and rewrites it at the end of the context, to keep the goal recent.
Import: the librarian already writes reference files; mask each fetched page once its reference
file is written, leaving the path.

Speed: overlaps with C5.

### C9. ACE, Agentic Context Engineering

Link: https://github.com/ace-agent/ace (1.4k stars, active); arXiv 2510.04618.

ACE keeps a playbook of lessons that grows by small edits after each task, instead of rewriting
the prompt. This is close to f improving itself from the simulated user's complaints. Import:
the rule that lessons are added and edited one at a time, never rewritten whole, so a good lesson
is not lost. It also keeps the playbook part of the prompt stable for the cache.

---

## 3. Guardrails

### G1. Constrained decoding as the first guardrail

Links: as S4.

An answer that cannot leave the schema needs no check and no retry. Import: enums for node ids
and relations, required fields, length limits on strings. This covers the two failures seen in
the i1 run.

### G2. Validate, then retry with the error

Link: Instructor, https://github.com/567-labs/instructor (14k stars, active).

Instructor validates the model's output against a typed schema and, on failure, sends the error
back and retries a set number of times. f already does this ("try 1: child 1: relation
undefined"). Import: only the rule to keep for checks a schema cannot express (no duplicate
children, every asked node rated), and a hard retry limit.

### G3. Limits with enforcers in the program

Links: opencode permissions and agents, https://opencode.ai/docs/permissions/ ; SMG, as S6.

opencode enforces `steps` per agent and stops a third identical tool call (`doom_loop`). SMG
enforces rate limits, retries with backoff, circuit breakers and priority admission. Import:
set `doom_loop` to deny for unattended runs, since nobody is there to answer "ask". Keep every
limit enforced by the program, as f already does for `expand.maxDepth`, never only stated in a
prompt.

### G4. Sandboxing

Link: Anthropic sandbox-runtime (`srt`), https://github.com/anthropic-experimental/sandbox-runtime
(5.5k stars, active, beta).

`srt` limits any process's file and network access without a container: sandbox-exec on macOS,
bubblewrap on Linux, and a proxy with a domain allowlist. Import: when f starts changing its own
code in the self-improvement loop, run the coder agent under `srt` with writes limited to its
worktree. The planning agents need no shell and should keep none.

### G5. Prompt injection from the references the librarian reads

Links: Beurer-Kellner et al., "Design Patterns for Securing LLM Agents against Prompt
Injections", arXiv 2506.08837 (June 2025); CaMeL, arXiv 2503.18813,
https://github.com/google-research/camel-prompt-injection (403 stars, research code, last push
June 2025); LlamaFirewall, arXiv 2505.03574, in https://github.com/meta-llama/PurpleLlama (4.4k
stars, active); Spotlighting, arXiv 2403.14720.

The design-patterns paper gives six patterns. Two fit f. Context minimization: the agents that
act see only the librarian's written reference files, never the raw page. Dual LLM: the agent
that reads untrusted text has no tools that matter. In f, the librarian reads the web and can
only write reference files; the expander and synthesizer read those files and never fetch. That
is already the safe shape. Import: keep it that way, and mark reference text as data with a
delimiter (Spotlighting). PromptGuard 2 (22M or 86M parameters, a classifier) can scan each
fetched page on the CPU cheaply; add it only if an injection is seen. CaMeL is a research
system; read it, do not run it.

Speed: none of these add a model call, except PromptGuard 2, which runs on the CPU in
milliseconds.

### G6. Looked at, not imported

NeMo Guardrails (https://github.com/NVIDIA-NeMo/Guardrails, 7.3k stars) and Guardrails AI
(https://github.com/guardrails-ai/guardrails, 7.5k stars) wrap chat turns with rails and
validators. G1 and G2 cover what f needs with less machinery.

---

## Sources

- f4 run: `reports/profile-e2e-i1-sim.txt`; `DESIGN_MULTIAGENT.md`;
  `opencode/plugin/pin-prompt.ts`; `vendor/opencode/packages/opencode/src/session/compaction.ts`
- vLLM reasoning outputs and thinking budget: https://docs.vllm.ai/en/latest/features/reasoning_outputs/
- SGLang thinking-budget issue: https://github.com/sgl-project/sglang/issues/25536
- vLLM forum, budget ignored in 0.18.0: https://discuss.vllm.ai/t/thinking-token-budget-silently-ignored-when-passed-via-extra-args-in-vllm-0-18-0/2533
- DEER: https://arxiv.org/abs/2504.15895
- Thinkless: https://arxiv.org/abs/2505.13379 ; AdaptThink: https://huggingface.co/papers/2505.13417
- Manus context engineering: https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
- Don't Break the Cache: https://arxiv.org/abs/2601.06007
- Anthropic context editing: https://platform.claude.com/docs/en/build-with-claude/context-editing
- Anthropic, Effective context engineering: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- vLLM speculative decoding: https://docs.vllm.ai/en/stable/features/speculative_decoding/
- vLLM Qwen3-Next recipe: https://docs.vllm.ai/projects/recipes/en/latest/Qwen/Qwen3-Next.html
- EAGLE: https://github.com/SafeAILab/EAGLE ; SpecForge: https://github.com/sgl-project/SpecForge
- SuffixDecoding: https://arxiv.org/abs/2411.04975 ; Arctic Inference docs: https://arcticinference.readthedocs.io/en/latest/suffix-decoding.html ;
  Snowflake blog: https://www.snowflake.com/en/engineering-blog/suffixdecoding-arctic-inference-vllm/
- XGrammar: https://github.com/mlc-ai/xgrammar ; XGrammar-2: https://blog.mlc.ai/2026/05/04/xgrammar-2-fast-customizable-structured-generation , https://arxiv.org/abs/2601.04426
- llguidance: https://github.com/guidance-ai/llguidance
- LLMCompiler: https://github.com/SqueezeAILab/LLMCompiler
- Continuum: https://arxiv.org/abs/2511.02230 , https://github.com/Hanchenli/vllm-continuum
- KVFlow: https://arxiv.org/abs/2507.07400
- Autellix: https://arxiv.org/abs/2502.13965
- LMCache: https://github.com/LMCache/LMCache , CacheBlend: https://docs.lmcache.ai/kv_cache_optimizations/blending.html
- SMG: https://github.com/smg-project/smg , https://pypi.org/project/tokenspeed-smg/
- RouteLLM: https://github.com/lm-sys/RouteLLM ; Arch-Router: https://arxiv.org/abs/2506.16655
- opencode: https://github.com/anomalyco/opencode ; permissions: https://opencode.ai/docs/permissions/
- Codex CLI: https://github.com/openai/codex ; compaction write-up (third party): https://codex.danielvaughan.com/2026/03/31/codex-cli-context-compaction-architecture/
- OpenHands condenser: https://docs.openhands.dev/sdk/arch/condenser ; https://openhands.dev/blog/openhands-context-condensensation-for-more-efficient-ai-agents
- The Complexity Trap: https://arxiv.org/abs/2508.21433
- SWE-agent: https://github.com/SWE-agent/SWE-agent ; mini-SWE-agent: https://github.com/SWE-agent/mini-swe-agent
- Aider repo map: https://aider.chat/docs/repomap.html
- Goose context management: https://goose-docs.ai/docs/guides/sessions/smart-context-management
- Harness source-code study of eleven agents: https://arxiv.org/abs/2609.00006
- ACE: https://github.com/ace-agent/ace
- Instructor: https://github.com/567-labs/instructor
- sandbox-runtime: https://github.com/anthropic-experimental/sandbox-runtime
- Design Patterns for Securing LLM Agents: https://arxiv.org/abs/2506.08837
- CaMeL: https://arxiv.org/abs/2503.18813
- LlamaFirewall: https://arxiv.org/abs/2505.03574
- Spotlighting: https://arxiv.org/abs/2403.14720
- NeMo Guardrails: https://github.com/NVIDIA-NeMo/Guardrails ; Guardrails AI: https://github.com/guardrails-ai/guardrails

## Metadata

- Star counts and last-push dates were read from the GitHub API on 2026-10-09.
- Token sums per role (Qwen unless noted), i1 run: expander 32 calls, 886k in (363k cached),
  64k out (58k thinking); rater 25 calls, 122k in (14k cached), 102k out (80k thinking);
  librarian 2 calls, 727k in (120k cached), 16k out; synthesizer 4 calls, 135k in (69k cached),
  3k out; librarian on GLM 3 calls, 3.71 M in (0 cached), 19k out; Director on GLM 4 calls,
  109k in, 3k out.
