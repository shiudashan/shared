# Survey: ready-made reviewers we could adopt instead of building

Checked on 2026-10-10. Stars, licences and release dates come from the GitHub API that day.
"Unverified" marks a claim taken from a third-party page and not confirmed in the vendor's own docs.

## Answer first

A ready-made reviewer meets only one of our four needs well: reviewing code diffs with local models.
Nothing ready-made reviews specs, plans or run logs against one person's reference feedback.
Nothing ready-made measures how well it agrees with one person.

Need by need:

- **(a) Code diffs of our project.** Met. Adopt **PR-Agent** (MIT, 13.3k stars, v0.47.0 on 2026-10-02).
  It runs on our own OpenAI-compatible endpoint. It reads AGENTS.md or CLAUDE.md as context. It
  can review a plain diff from a file or stdin and write JSON, so S can call it without GitHub.
  If we later want a server with team memory and rule generation, **Kodus** (AGPL-3.0) is the
  self-hosted alternative.
- **(b) Specs, plans and run logs against the person's reference feedback.** Not met. Every tool
  takes written rules or a prompt. None takes a bank of the person's past verdicts with reasons.
  The closest general tools are `codex review "<instructions>"`, the OpenHands review skill, and
  Continue's markdown "checks". Each is a prompt runner. The person model would still be ours.
- **(c) Learning one person's standard from approvals and rejections.** Partly met, in a form we
  cannot use. Greptile, Cursor Bugbot, CodeRabbit, Qodo and LiveReview learn from reactions,
  replies or which comments got fixed. They learn per team. When one person gives all the
  feedback, the team is that person, so the scope is not the obstacle. The obstacles are three.
  The learning runs only on code pull requests. It runs in the vendor's cloud on the vendor's
  models, except LiveReview and enterprise self-host deals. And the learned store is mostly not
  readable by S. Kodus has switched its reaction learning off, because "a thumbs-up or
  thumbs-down alone does not explain why a suggestion was rejected."
- **(d) Local models.** Met for (a): PR-Agent, Kodus, Gito, LiveReview, OpenHands and Continue all
  accept a custom endpoint. Codex accepts one only if the endpoint speaks the Responses API.
  Claude Code review does not support non-Claude models. Greptile, CodeRabbit and Qodo allow
  their own models only on enterprise self-host contracts.

What remains ours to build: the person's example bank with reasons, the rules distilled from it,
the "decide only when sure, else ask the person" gate, review of non-code artifacts, and the
agreement measure. These are the parts the earlier survey (`survey-simulated-reviewer.md`)
already laid out. The ready-made tools replace only the plumbing around code diffs.

One reusable measuring tool exists: Martian's **Code Review Bench** (MIT). Its online pipeline
uses an LLM to decide which bot comments the developer actually fixed. We could point it at our
own reviewer's comments on our own pull requests.

## 1. Open source, self-hostable with our own LLM endpoint

**PR-Agent** ([The-PR-Agent/pr-agent](https://github.com/The-PR-Agent/pr-agent)). MIT per the
LICENSE file. 13.3k stars. v0.47.0, 2026-10-02. Qodo donated it to a community organisation;
it is "not the Qodo free tier."
- Endpoint: yes. `[openai] api_base` or `OPENAI__API_BASE`, routed through LiteLLM. The docs name
  vLLM serving Qwen and show `extra_body` to turn off Qwen thinking. Ollama is documented too.
- What it reviews: pull requests on GitHub, GitLab, Bitbucket, Azure DevOps, Gitea, Gerrit; a
  local git branch; or a raw unified diff from stdin or a file (`plain_diff` provider, JSON
  output). So it reviews any text that can be put in a diff, including markdown. It does not
  review a whole document that has no diff.
- Customisation: `extra_instructions` per tool, `repo_context_files` (default `AGENTS.md`),
  `.pr_agent.toml` in the repo, an external config URL, `num_max_findings` (default 3).
- Learning: none. It keeps earlier findings (`persistent_finding_state`) so it does not re-raise
  them reworded, and skips findings whose GitLab thread a human resolved. That is suppression of
  repeats, not learning a standard.

**Kodus** ([kodustech/kodus-ai](https://github.com/kodustech/kodus-ai)). AGPL-3.0 per README badge
(GitHub reports the licence as "Other"). 1.5k stars. Release web-1.2.7, 2026-10-06.
- Endpoint: yes, "any OpenAI-compatible endpoint"; README names GLM and Kimi.
- What it reviews: pull requests; a CLI reviews local changes and has a "business validation"
  mode. Free self-hosted Community edition allows up to 10 rules.
- Customisation: "Kody Rules" in plain language, scoped by repo or path; imports CLAUDE.md,
  .cursorrules and similar files; "Memories" saved from `@kody remember` and from PR chat, with an
  optional approval step; automatic rule generation from review history.
- Learning from accept/reject: switched off. The docs say reactions "do not train a model, build
  preference clusters, or filter the next review."

**Gito** ([Nayjest/Gito](https://github.com/Nayjest/Gito)). MIT. 445 stars. v4.5.0, 2026-09-05.
GitHub Action or CLI. `LLM_API_BASE` accepts any OpenAI-compatible server; vLLM, SGLang and Ollama
are listed. Reviews diffs. No learning found.

**LiveReview** ([HexmosTech/LiveReview](https://github.com/HexmosTech/LiveReview)). Source-available,
needs a free licence key; not an OSI licence. 64 stars. v1.0.9, 2026-10-05. Self-hosted; brings
its own fine-tuned model or your key, including self-hosted Ollama. Stores "learnings" from
merge-request discussions per organisation. The only self-hosted tool found whose learning store
is on by default.

**OpenHands PR review** ([docs](https://docs.openhands.dev/sdk/guides/github-workflows/pr-review)).
MIT. OpenHands has 90k stars, v1.26.0 on 2026-10-08. A GitHub workflow runs an agent with a
`/codereview` skill. Any LiteLLM model, so our endpoint works. Customised by a skill file in the
repo. The agent can read whole files, so a skill can review documents. No learning.

**Continue checks** ([continuedev/continue](https://github.com/continuedev/continue)). Apache-2.0.
36k stars. Each markdown file in `.continue/checks/` is a prompt that runs on a pull request and
reports pass or fail as a GitHub status check. The `cn` CLI accepts OpenAI-compatible models.
Pass/fail per check suits a rule-shaped standard. No learning.

**Codex CLI `codex review`** ([openai/codex](https://github.com/openai/codex)). Apache-2.0. 128k
stars. Reviews uncommitted changes, a base branch, a commit, or follows a free-text prompt.
`review_model` sets the reviewing model. Custom providers take a `base_url`, but `wire_api` is
"`responses` is the only supported value", so our router must serve the Responses API.

**Shippie** ([mattzcarey/shippie](https://github.com/mattzcarey/shippie)). MIT. 2.5k stars. Agent
loop over the diff with codebase tools. Providers listed: Anthropic, OpenAI, OpenRouter,
Cloudflare. A custom base URL is unverified.

**Small GitHub Actions.** [anc95/ChatGPT-CodeReview](https://github.com/anc95/ChatGPT-CodeReview)
(ISC, 4.5k stars, `OPENAI_API_ENDPOINT` settable), [villesau/ai-codereviewer](https://github.com/villesau/ai-codereviewer)
(MIT, last push 2024). Diff-only prompt wrappers. No learning.

**Reviewdog** ([reviewdog/reviewdog](https://github.com/reviewdog/reviewdog)). MIT. 9.6k stars.
Not a reviewer. It posts any tool's findings as pull-request comments. Useful as output plumbing
if S's reviewer emits its findings in reviewdog's JSON format.

**Bito Code Review Agent** ([gitbito/CodeReviewAgent](https://github.com/gitbito/CodeReviewAgent)).
MIT repo, 67 stars, last push 2025-11. The self-hosted agent still calls Bito's service with a Bito
key (unverified). Not usable with our models as far as found.

**No longer a candidate.** CodeRabbit's open-source `ai-pr-reviewer` was archived in 2024 and now
returns 404. Sweep turned into a JetBrains coding assistant. Aider has no review mode that I found.

**Released reviewer models.** Microsoft [CodeReviewer](https://huggingface.co/microsoft/codereviewer)
(2022, arXiv 2203.09095) is a small pre-LLM model for diff comments; it is far below current
Qwen-class models. Google's AutoCommenter was never released.

**Static analysis with LLM triage.** Semgrep Assistant "Memories" learn from triage decisions,
scoped by project or rule, with admin approval; Semgrep reports 95–96% agreement with users. It is
security-only and cloud-only. CodeQL with Copilot Autofix fixes alerts; it does not learn.

## 2. Commercial, by API or app

None of these lets S send an arbitrary document plus a person's examples and get a review back.
The programmatic surfaces are CLIs that review a local git diff, and a few data APIs.

**CodeRabbit.** Essentials $24, Team $48, Advanced $72 per developer per month (annual).
- API: a REST API for metrics, learnings, users and audit logs, mostly Enterprise only. Reviews
  are triggered by the app or by the CLI (`--agent` gives NDJSON) with an API key.
- Own models: only self-hosted Enterprise, which needs 500 or more seats.
- Learning: "learnings" are natural-language preferences it extracts from chat replies, scoped to
  repo or organisation, viewable and editable. Path instructions and guideline files
  (CLAUDE.md, AGENTS.md) add rules.
- Data: does not train on customer code; retention can be turned off.

**Greptile.** Free Starter (1 developer, 50 credits); Pro $30 per seat per month, $1 per extra
credit; Enterprise custom.
- API: CLI with JSON output and an MCP server. No public review REST API in the current docs.
- Own models: self-hosted Enterprise accepts "any OpenAI-compatible API," but its deployment page
  asks for a Claude- or GPT-class model and an embeddings model.
- Learning: from thumbs, replies, human review comments, and which comments were addressed
  between first and last commit. It suppresses comment kinds the team ignores. It claims an 80%
  drop in ignored comments (vendor figure, no method given).

**Qodo** (formerly Qodo Merge). Pro Team $30 for 2,500 credits (about 18 reviews); Enterprise
custom with on-prem, air-gapped and bring-your-own-key.
- Learning: "auto best practices" collects accepted suggestions on a wiki page and applies the
  recurring ones; the 2.1 rules system proposes rules from PR discussions.

**Cursor Bugbot** (and Graphite, bought by Cursor in December 2025). Bugbot "learned rules" are
drafted from reactions and replies, promoted when they gather signal, and disabled when they stop
helping. Cursor reports a 78% resolution rate, judged by an LLM at merge time (vendor figure).
Graphite Team is about $40 per user per month (third-party pages). Their models only.

**GitHub Copilot code review.** Included in paid Copilot plans; one premium request per review.
Custom instructions files. Model switching "is not supported." Learning from feedback not
documented.

**Claude Code Review (Anthropic).** Team and Enterprise, research preview, $15–25 per review on
average, about 20 minutes. Tuned with CLAUDE.md or REVIEW.md. Reactions are collected by
Anthropic "to tune the reviewer," not per customer. The open-source GitHub Action and the local
`/code-review` command run on Claude only; Anthropic "doesn't support routing Claude Code to
non-Claude models."

**OpenAI Codex review.** `@codex review` on GitHub with ChatGPT plans; flags only P0 and P1 issues;
follows AGENTS.md. The open-source CLI is covered in section 1.

**Gemini Code Assist on GitHub.** Free GitHub app (launched as a preview); `.gemini/styleguide.md`
and `config.yaml`. Gemini only. Current review quota not found.

**Amazon.** CodeGuru Reviewer has been in maintenance mode since 2025-11-07; AWS points to Q
Developer, whose plugins and paid plans reach end of support on 2027-04-30 (secondary report,
unverified). Not a candidate.

**Sourcegraph Cody.** Free and Pro ended 2025-07-23; Enterprise only. No dedicated reviewer found.

**Ellipsis, Korbit, CodeAnt.** Cloud apps. Ellipsis prices by usage; CodeAnt about $24 per user per
month with on-prem only on Enterprise (third-party pages); Korbit's site is still live. None
documents use of our own models or a person-level learning store.

**Published agreement and acceptance numbers.** All are per team and mostly vendor-run. Martian's
Code Review Bench is the one independent, open benchmark. On its online data CodeRabbit led in
early 2026 with 51.2% F1; Greptile reports 60.8% F1 and 76.2% precision in a July 2026 snapshot
(vendor-reported). These measure "did the developer fix it," not "did this person agree."

## 3. Fit to our needs

**(a) Code diffs.** PR-Agent covers it on our GPUs today. Configure `OPENAI.API_BASE` to the
router, set `custom_model_max_tokens` to the served context, and feed the person's rules through
`extra_instructions` or `repo_context_files`. Its plain-diff mode lets S call it on any commit.
Kodus covers the same need with a server, a database and a rule editor, at the cost of AGPL and
more moving parts.

**(b) Non-code artifacts.** Partly covered as plumbing only. PR-Agent reviews a diff of a spec. An
OpenHands skill, a Continue check or `codex review "<prompt>"` can review a whole plan or log
with a prompt we write. The prompt, with the person's examples and distilled rules inside it, is
the part we build.

**(c) One person's standard.** The learning loops exist but are closed. Each keeps its learned
rules inside the vendor's system, and each learns only from code pull-request events. CodeRabbit's
Enterprise API exports learnings; LiveReview and self-hosted Kodus keep them in our own database.
None stores a reason with each verdict, and Kodus withdrew its reaction learning for lack of one.
We build the store, the reasons, the rule distillation, the confidence gate and the agreement
measure.

**(d) Local models.** PR-Agent, Kodus, Gito, LiveReview, OpenHands and Continue run on our router.
Codex needs a Responses-API endpoint. Everything commercial needs an enterprise contract to use our
models, and Claude Code cannot.

## Sources

Open source
- PR-Agent: https://github.com/The-PR-Agent/pr-agent ; model docs https://github.com/The-PR-Agent/pr-agent/blob/main/docs/docs/usage-guide/changing_a_model.md ; configuration https://github.com/The-PR-Agent/pr-agent/blob/main/pr_agent/settings/configuration.toml ; plain diff provider https://github.com/The-PR-Agent/pr-agent/blob/main/pr_agent/git_providers/plain_diff_provider.py
- Qodo donating PR-Agent: https://futurumgroup.com/insights/qodo-hands-pr-agent-to-the-community-will-open-governance-accelerate-ai-code-review/
- Kodus: https://github.com/kodustech/kodus-ai ; feedback docs https://docs.kodus.io/how_to_use/en/code_review/learning/kody_learning ; memories https://docs.kodus.io/knowledge_base/en/how-to-teach-ai-your-team-conventions
- Gito: https://github.com/Nayjest/Gito
- LiveReview: https://github.com/HexmosTech/LiveReview
- OpenHands PR review: https://docs.openhands.dev/sdk/guides/github-workflows/pr-review
- Continue checks: https://www.continue.dev/docs ; https://github.com/continuedev/continue
- Codex CLI: https://developers.openai.com/codex/cli/reference ; config https://developers.openai.com/codex/config-reference
- Shippie: https://github.com/mattzcarey/shippie
- ChatGPT-CodeReview: https://github.com/anc95/ChatGPT-CodeReview ; ai-codereviewer: https://github.com/villesau/ai-codereviewer
- Reviewdog: https://github.com/reviewdog/reviewdog
- Bito: https://github.com/gitbito/CodeReviewAgent ; https://docs.bito.ai/ai-code-review-agent/agent-settings
- CodeRabbit ai-pr-reviewer (archived): https://www.sourcepulse.org/projects/828398
- Microsoft CodeReviewer: https://huggingface.co/microsoft/codereviewer ; https://arxiv.org/abs/2203.09095
- Google AutoCommenter paper: https://arxiv.org/abs/2405.13565
- Semgrep Assistant memories: https://semgrep.dev/blog/2025/making-zero-false-positive-sast-a-reality-with-ai-powered-memory ; https://ai.semgrep.dev/blog/2025/announcing-ai-noise-filtering-and-triage-memories
- Copilot Autofix: https://docs.github.com/en/code-security/concepts/code-scanning/copilot-autofix-for-code-scanning
- Martian Code Review Bench: https://github.com/withmartian/code-review-benchmark ; https://codereview.withmartian.com

Commercial
- CodeRabbit: plans https://docs.coderabbit.ai/management/plans ; API https://docs.coderabbit.ai/api/index ; self-hosted https://docs.coderabbit.ai/self-hosted/overview ; learnings https://docs.coderabbit.ai/knowledge-base/learnings ; CLI https://docs.coderabbit.ai/cli/index ; FAQ https://docs.coderabbit.ai/faq ; benchmark post https://coderabbit.ai/blog/coderabbit-tops-martian-code-review-benchmark
- Greptile: pricing https://www.greptile.com/pricing ; self-host https://www.greptile.com/docs/security/selfhost ; deployment https://www.greptile.com/docs/deployment-options ; learning https://www.greptile.com/docs/how-greptile-works/memory-and-learning ; docs index https://greptile.com/llms.txt ; benchmark https://www.greptile.com/content-library/greptile-martian-code-review-benchmark
- Qodo: pricing https://www.qodo.ai/pricing/ ; best practices https://docs.qodo.ai/v1/features/best-practices.md ; 2.0/2.1 https://www.qodo.ai/resources/qodo-2-0-2-1-whats-new-and-whats-next/
- Cursor Bugbot: https://cursor.com/changelog/04-08-26 ; https://cursor.com/blog/building-bugbot
- Graphite acquisition: https://fortune.com/2025/12/19/cursor-ai-coding-startup-graphite-competition-heats-up/ ; pricing (third party) https://www.stackpick.net/pricing/graphite/
- GitHub Copilot code review: https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/code-review
- Claude Code Review: https://code.claude.com/docs/en/code-review ; gateway https://code.claude.com/docs/en/llm-gateway ; Action https://github.com/anthropics/claude-code-action
- Codex on GitHub: https://developers.openai.com/codex/integrations/github
- Gemini Code Assist: https://developers.google.com/gemini-code-assist/docs/customize-repo-review ; https://blog.google/technology/developers/gemini-code-assist-free/
- Amazon: https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/codeguru-reviewer-availability-change.html ; Q Developer end of support (secondary) https://letsdatascience.com/news/amazon-q-developer-announces-end-of-support-timeline-97a57c03
- Sourcegraph Cody: https://sourcegraph.com/blog/changes-to-cody-free-pro-and-enterprise-starter-plans
- Ellipsis: https://ellipsis.dev/pricing ; Korbit: https://www.korbit.ai ; CodeAnt (third party): https://aicodereview.cc/tool/codeant-ai
