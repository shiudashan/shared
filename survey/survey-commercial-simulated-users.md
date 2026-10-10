# Survey: commercial simulated users and hosted services

Checked on 2026-10-10. "Unverified" marks a claim from a third-party page that the vendor's own
docs did not confirm. Open-source simulators (tau2, openevals, DeepEval, promptfoo, LangWatch
Scenario) and the research on one-person simulators are in the earlier surveys and are not
repeated here.

## Answer first

No commercial product meets our needs. None takes one person's labelled feedback and plays that
person. None gives critique on that person's behalf. None publishes how well it agrees with one
person on work like ours.

Need by need:

- **(a) Driving our prototype through rounds.** Met in shape, not as a product to adopt. Every
  agent-testing product does the same thing: an LLM gets a persona and a goal, talks to your
  agent until a stop signal or a turn cap, then separate judges score the transcript. The
  hosted ones (Maxim, Snowglobe, Confident AI, Coval, Cekura) need our prototype behind an HTTP
  endpoint or a phone number and run the simulator on the vendor's models. The cloud SDKs
  (AWS AgentCore and its open Strands Evals base, Google ADK and the Gemini Enterprise agent
  platform, Azure AI Evaluation `Simulator`) call our code through a Python callback. That is
  the shape we already have. Two shapes are worth borrowing: AWS's actor output of
  reasoning, message and stop flag per turn, and ADK's three stock personas (expert, novice,
  evaluator).
- **(b) Feedback on runs on one person's behalf.** Not met. In every agent-testing product the
  simulated user only plays turns. Feedback comes from judges scored against written
  assertions, not from the simulated user, and not as one person. Synthetic-research products
  (Synthetic Users, Electric Twin) do give critique, but as a population persona reacting to a
  concept, on vendor models, without a public API.
- **(c) Learning one person's standard.** Not met. Three products model one person: Simile
  (twins built from interviews and chat histories), Viven (a model per employee, built from
  that employee's email, documents and meetings) and Delphi (a clone built from a person's
  published content). All three learn from what the person wrote or said, not from labelled
  verdicts with reasons. None reports agreement with one person on review or prioritisation.
  Simile sells populations through a web interface at $150,000 or more a year. Viven and
  Delphi have no public API pricing.
- **Local models.** Only the open SDK pieces can use our OpenAI-compatible endpoint. Strands
  supports Ollama and LiteLLM as model providers; whether `ActorSimulator` accepts them is
  unverified. ADK's simulator `model` is configurable; non-Gemini use is unverified. Every
  hosted product runs on the vendor's models. Synthetic Users states that model choice is not
  configurable by users.

What to adopt: nothing as a dependency. What remains ours: the person's example bank, the
rules distilled from it, the feedback and prioritisation roles, the agreement measure, and
running on local models. These are the parts the earlier surveys already laid out. The
commercial market adds dashboards and voice infrastructure, which we do not need.

Fidelity: no agent-testing vendor publishes how closely its simulated user matches real users.
The only fidelity numbers come from the synthetic-research vendors, are self-reported, and
measure populations: Simile 85 to 99% (CVS reports 95% replication of known answers), Aaru
median Spearman 0.90 over 53 questions against an EY study, Electric Twin 95% and "up to 96%
(1-MAE)", Artificial Societies "over 80%" on predicting social media performance.

## 1. Cloud SDKs: simulators that call our code

**AWS Bedrock AgentCore user simulation (public preview).** An "actor" plays the user. The
dataset gives `actor_profile` (`context`, `goal`, optional `traits`), a first `input`,
`max_turns` (default 10) and natural-language `assertions`. Each turn the actor returns
**reasoning**, **message** and a **stop** flag. Judges such as `Builtin.GoalSuccessRate` score the
session afterwards. Persona: scripted, goal-driven, population-style. Conditioning on one
person's labelled examples: not supported beyond what we write into `context`. Feedback: the
reasoning field explains the actor's moves "for debugging"; it is not critique. Validation: none
published. API: Python SDK (`pip install 'bedrock-agentcore[simulation]'`) with on-demand and
batch runners. Models: a Bedrock `model_id` only. Price: Bedrock invocation charges for the
actor, plus on-demand evaluation charges.

**Strands Evals `ActorSimulator` (AWS, Apache-2.0, unverified licence date).** The open
component behind the AgentCore pattern. It can generate an actor profile from a test case, or
take a custom `ActorProfile`. The simulated user has a goal-completion tool it can call to
decide to stop. Validation: none published. Models: Strands supports Bedrock, Anthropic,
Ollama and LiteLLM; whether `ActorSimulator`'s `model` argument accepts a LiteLLM or Ollama
model is unverified. Price: free.

**Google ADK user simulation (ADK Python 1.18.0 and later) and the Gemini Enterprise agent
platform.** A `ConversationScenario` has a `starting_prompt`, a `conversation_plan` (hidden
goals and how to answer the agent's questions) and a `user_persona`. Stock personas: EXPERT
(corrects the agent, troubleshoots once), NOVICE (waits to be asked, never troubleshoots),
EVALUATOR (detail-oriented, answers only relevant questions). `custom_instructions` replaces
the default prompt, with placeholders for stop signal, plan, history and persona. Defaults:
`gemini-flash-latest`, 20 turns in ADK; 5 turns on the hosted platform, which can also generate
scenarios from the agent's instructions and tools. Conditioning on examples: not documented.
Feedback: none from the simulator. Validation: none published. Models: configurable;
non-Gemini unverified. Price: model usage; no simulation-specific price found.

**Azure AI Evaluation `Simulator` (preview, Foundry classic, hub projects only).** Generates
queries from a text or index, then plays a user with a `task` and a `mood` against a callback.
The user prompt is a replaceable Prompty file. `conversation_turns` fixes the first turns.
Models: an Azure OpenAI `model_config`. The page says it "will not work for Foundry projects".
The new Foundry offers synthetic dataset generation (preview) and "full-conversation evaluation
on simulated data", without a persona simulator in its docs. `AdversarialSimulator` is for
safety red-teaming on a Microsoft-hosted model. Validation: none published. Price: Azure model
usage.

## 2. Products that model one specific person

**Simile.** Founded by Joon Sung Park, author of the "1,000 people" generative-agents work
covered in the earlier survey. Raised $100M (February 2026) and $200M at a $2B valuation (July
2026). Builds "agentic twins" from interviews and chat data; CVS used 400,000 twins and
calibrates them with its own past surveys and support interactions. One person vs population:
twins are individuals, sold as populations. Conditioning on one person's labelled examples: not
offered to customers as far as found. Feedback: twins answer survey and interview questions.
Validation: 85 to 99% by group, self-reported; CVS reports 95% on known answers. API: none
found; access is a web interface. Data: consent claimed; role-based access. Price: $150,000 to
several million dollars a year (Gigazine report).

**Viven.** Spun out of Eightfold; $35M seed (October 2025). Builds "a personalized AI model for
every employee", grounded in that employee's emails, documents, code, chats and meetings,
so colleagues can query the twin when the person is away. The employee can see every query and
who asked. Conditioning: on work artifacts, not labelled verdicts. Feedback: answers questions
as the person. Validation: none published. API and price: none found.

**Delphi.** A clone of one person, trained on that person's text, audio and video, answering in
their voice and citing sources. Conditioning: on published content, not on verdicts. Validation:
none published. API: on the custom-priced top tier only (unverified). Price: about $79 to $399 a
month for lower tiers (unverified, sources disagree).

## 3. Synthetic research products (populations that give critique)

**Synthetic Users.** Interviews with synthetic personas built on OCEAN traits from demographic
and psychographic inputs. A study can be enriched with up to three PDFs (for example past
interviews) by retrieval. This is the closest a product comes to "condition on one person's
past feedback", but it informs answers and does not set the persona. Gives critique of concepts.
Model selection "not configurable by end users". No public API found. Validation: a second-hand
report of Nielsen Norman Group finding sycophancy (unverified). Price: an "old" sheet lists
$22,999 a year for 1,000 interviews; third parties report a few dollars per interview.

**Electric Twin.** Synthetic populations built from a client's surveys, interviews and focus
groups; also one-to-one discussions. Validation: 95% (with LSE) and "up to 96% (1-MAE)",
vendor-reported. API: bespoke build per the UK G-Cloud listing, OpenAPI docs, no sandbox. ISO
27001; does not train general models on customer data. Price: not public.

**Aaru.** Population simulation for forecasting (Lumen). Validation: median Spearman 0.90 over
53 questions against EY's wealth study, self-reported; a September 2026 evaluation across 2,993
questions. No public developer API. Price: enterprise.

**Artificial Societies.** Networks of personas modelling how opinions spread. "Over 80%"
accuracy predicting social media performance, vendor-reported. API and price not found.

**Expected Parrot (EDSL, MIT, 503 stars).** Open-source survey simulation with agents defined
by traits; hosted Coop runs surveys with free credits and can add human respondents. Uses your
own API keys or theirs; local-model support unverified. A population tool; no one-person
conditioning documented.

## 4. Agent-testing platforms (hosted)

All share one design: a persona prompt plus a scenario plays the user; judges score afterwards.
None conditions on one person's labelled feedback; none has the simulated user critique; none
publishes simulator fidelity.

- **Confident AI (DeepEval cloud).** Hosted home of the DeepEval simulator. Adds reusable
  persona objects (`characteristics`, `metadata`) shared across goldens. Chat simulations from
  the Starter plan. Price: Free; Starter $200/month; Team $2,000/month; on-prem on Enterprise.
- **LangSmith.** No hosted simulator; it logs runs of the open `openevals` simulator as
  experiments. Price: Developer free (5k traces); Plus $39/seat/month; self-host on Enterprise.
- **Maxim AI.** Agent simulation from a scenario, a persona ("frustrated customer"), a turn cap,
  tools and context sources. REST trigger `POST /v1/test-runs/simulations`. Model choice for the
  simulated user not documented. Price: $29 and $49 per seat per month (third-party,
  unverified); in-VPC on Enterprise.
- **Snowglobe (Guardrails AI).** Generates many personas from a short description of the
  chatbot, runs them against an endpoint, scores each conversation, and focuses later runs on
  the riskiest personas. Can export judge-labelled datasets. Price not found.
- **Future AGI.** Text and voice simulation; 18 stock personas plus custom; scenarios can come
  from customer-profile datasets. Core libraries Apache-2.0. Free tier includes 1M text
  simulation tokens; then metered.
- **Okareo.** "Drivers" are synthetic users with persona, goals and context; Python SDK; CI
  gating. Details mostly third-party.
- **Collinear TraitMix.** Composes user traits (impatience, confusion, sarcasm) in activation
  space; offered with Together Evals. Population traits only.
- **Galileo, Arize (Phoenix and AX), Braintrust.** No simulated-user product found in their own
  docs. Arize and Galileo score sessions after the fact; Galileo's agent leaderboard uses a user
  simulator internally to rank agents.
- **Patronus AI.** "Generative Simulators" and "Digital World Models" simulate software
  environments for agent training, not users. Preview (June 2026).
- **Salesforce Agentforce Testing Center, Kore.ai.** Synthetic tests and simulated user profiles
  inside their own agent platforms; usable only for agents built there. Persona details for
  Salesforce unverified.

## 5. Voice-agent testing

Coval, Cekura, Hamming, Bluejay and Cyara Botium test voice agents by phone or WebSocket.
Personas set voice, accent, noise, interruption rate and behaviour. Hamming builds personas from
production call patterns and recommends goal, constraints, fixtures and assertions per persona.
Bluejay builds "digital humans" from agent configuration and real customer data (third-party).
These model a population of callers, not one person. Prices: Coval $100, $500 and from $4,500 a
month; Cekura $0.25 per voice minute or $500 a month; Hamming not public. Botium's LLM features
found date from 2023 (GPT-3 generated user examples).

## 6. Model providers and human services

- **OpenAI.** No simulated-user feature found in its Evals or agent-evals docs. Absence
  unverified.
- **Anthropic.** No product. Petri and Bloom are open-source auditing tools in which a model
  plays simulated users to probe another model's behaviour; they measure models, not stand in
  for a person.
- **Scale AI, Surge AI, Invisible.** No simulated-user product found. They sell human data work;
  human role-play testers would be a services contract. Not checked further.

## Sources

- AWS AgentCore user simulation: https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/user-simulation.html ; simulation overview: https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/simulation.html
- Strands Evals simulators: https://strandsagents.com/docs/user-guide/evals-sdk/simulators/ ; blog: https://strandsagents.com/blog/simulate-realistic-users-multi-turn-agents-strands-evals/ ; LiteLLM provider: https://strandsagents.com/docs/user-guide/concepts/model-providers/litellm/
- Google ADK user simulation: https://adk.dev/evaluate/user-sim/ ; announcement: https://developers.googleblog.com/en/announcing-user-simulation-in-adk-evaluation/
- Gemini Enterprise agent platform, simulate agent behaviour: https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-simulated
- Azure AI Evaluation simulator (classic): https://learn.microsoft.com/en-us/azure/foundry-classic/how-to/develop/simulator-interaction-data ; Foundry synthetic datasets: https://learn.microsoft.com/en-my/Azure/foundry/observability/how-to/evaluation-dataset-synthetic ; evaluate apps: https://learn.microsoft.com/en-my/Azure/foundry/how-to/evaluate-generative-ai-app
- Simile: https://thenextweb.com/news/simile-200-million-agentic-twins-ai-market-research ; https://gigazine.net/gsc_news/en/20260309-ai-digital-twins-market-research-simile ; https://siliconangle.com/2026/02/12/ai-digital-twin-startup-simile-raises-100m-funding/
- Viven: https://techcrunch.com/2025/10/15/eightfold-co-founders-raise-35m-for-viven-an-ai-digital-twin-startup-for-querying-unavailable-coworkers ; https://foundationcapital.com/announcing-our-investment-in-viven-a-personalized-ai-for-every-employee/
- Delphi: https://venturebeat.com/ai/you-can-now-make-an-ai-clone-of-yourself-or-anyone-else-living-or-dead-with-delphi ; pricing (third-party): https://toolradar.com/tools/delphi/alternatives ; https://softwarefinder.com/artificial-intelligence/delphi-ai
- Synthetic Users: https://legal.syntheticusers.com/product-documentation/product-features ; https://legal.syntheticusers.com/ai/system-architecture ; old pricing: https://legal.syntheticusers.com/docx/product-documentation/pricing-old.docx
- Electric Twin: https://www.applytosupply.digitalmarketplace.service.gov.uk/g-cloud/services/763372757220010 ; https://www.trustradius.com/products/electric-twin
- Aaru: https://aaru.com/ ; https://providers.apievangelist.com/providers/aaru/
- Artificial Societies: https://www.silicon.co.uk/press-release/artificial-societies-reinvents-market-research-with-accessible-ai-societal-simulator ; https://societies.io/compare/simile
- Expected Parrot EDSL: https://github.com/expectedparrot/edsl
- Confident AI personas: https://www.confident-ai.com/docs/reference/sdk/personas ; pricing: https://www.confident-ai.com/pricing
- LangSmith multi-turn simulation: https://docs.langchain.com/langsmith/multi-turn-simulation ; pricing: https://www.langchain.com/pricing
- Maxim: https://www.getmaxim.ai/docs/simulations ; trigger API: https://www.getmaxim.ai/docs/test%20runs/simulation/trigger-simulation-test-run.md ; pricing (third-party): https://freetier.co/directory/products/maxim-ai
- Snowglobe: https://guardrailsai.com/snowglobe/docs/overview ; https://guardrailsai.com/snowglobe/docs/faq
- Future AGI: https://futureagi.com/pricing ; https://docs.futureagi.com/home
- Okareo: https://pypi.org/project/okareo ; https://tooldirectory.ai/tools/okareo
- Collinear TraitMix: https://together.ai/blog/collinear-simulations-together-evals
- Galileo (third-party): https://www.respan.ai/market-map/compare/ashr-vs-galileo-ai ; Arize sessions: https://arize.com/docs/ax/arize-ai-for-agents
- Patronus AI: https://thenextweb.com/news/patronus-ai-50m-series-b-agent-simulation
- Salesforce Agentforce Testing Center: https://www.businesswire.com/news/home/20241120646715/en ; Kore.ai evals: https://docs.kore.ai/agent-platform/evals
- Coval: https://docs.coval.ai/concepts/personas/overview ; pricing: https://www.coval.ai/pricing
- Cekura pricing: https://www.cekura.ai/pricing
- Hamming: https://hamming.ai/resources/voice-agent-test-personas-support-calls-template ; pricing (third-party): https://www.evaluagent.com/?p=10417
- Bluejay: https://www.coval.ai/blog/cekura-vs-bluejay ; https://assemblyai.com/docs/voice-agents/voice-agent-api/test-with-bluejay
- Cyara Botium: https://cyara.com/news/cyara-announces-openai-gpt-3-integration-to-accelerate-conversational-ai-chatbot-training-and-testing
- Anthropic Bloom and Petri: https://www.anthropic.com/news/bloom
- OpenAI agent evals (third-party description): https://eesel.ai/blog/openai-agent-evals

## Metadata

Written in plan mode, so it sits in the plan file. Its intended path is
~/shared/survey/survey-commercial-simulated-users.md.
