# LLM request routers: survey for Box A

Date: 2026-10-07. Every verdict comes from each project's source at its current main branch, cloned that day. Docs were also read. Where docs and source disagree, the source wins, and the disagreement is noted.

## Recommendation

Use **Shepherd Model Gateway (SMG)**. It is the SGLang model gateway, now spun out as its own engine-agnostic project (smg-project/smg). It is the only candidate that meets requirements 1, 3, 4, 6 and 7 for stock vLLM servers with no code.

- **Requirement 2 is met with configuration.** SMG has a built-in wildcard model, `"unknown"`, that routes across every worker. The client sends `"unknown"` as its no-preference name. Each vLLM server adds `unknown` as a second served name, so it accepts the request and answers with its real model name.
- **Requirement 5 is met for passthrough.** "Count only priority-0 requests when judging room" needs one custom policy, about 100 to 150 lines of Rust.

Every other candidate either needs code for requirement 2 and for real load awareness, or does not fit at all. The reasons:

- **vllm-project/production-stack router:** its `/metrics` scraper is unused for routing, it answers `auto` with a 404, and it has no arm64 image.
- **LiteLLM:** it has no prefix-aware routing, it uses no server load, and it consumes the `priority` field itself.
- **llm-d, Dynamo and semantic-router:** they do not fit this setup at all.

## How to read the verdicts

The requirement numbers are those of the request:

1. One address; `/v1/models` lists both models.
2. A named model goes to its server. A no-preference request goes to the server with the most room, with `model` rewritten.
3. Prefix-aware routing, with no client header.
4. Load read from the servers themselves.
5. `priority` passed through; ideally only priority-0 requests are counted when judging room.
6. Health checks; streaming passed through as it arrives.
7. One container on arm64 without Kubernetes; maturity.

With one server per model, requirements 3 and 4 only matter for no-preference requests. A request naming a model has exactly one candidate server. So the real question for 3 and 4 is whether the router can choose *across the two models* by prefix and by load.

## Shepherd Model Gateway (smg-project/smg, v1.11.0)

1. **Met.**
   - It asks each worker's `GET /v1/models` for its model id.
   - It detects vLLM from `owned_by: "vllm"` (`model_gateway/src/workflow/steps/local/detect_backend.rs`, `discover_metadata.rs` L228-263).
   - The gateway's `/v1/models` lists every worker's model (`model_gateway/src/endpoints/models.rs` L88-101).
   - Plain `--worker-urls` is enough. `--enable-igw` is not needed.
2. **Met with configuration.**
   - A named model is filtered to its workers (`routers/http/router.rs` L252-278).
   - An unknown name such as `auto` gets 404 `model_not_found`.
   - The literal model `"unknown"` selects from all workers (`worker/registry.rs` L607-616, `get_routing_pool`).
   - SMG does not rewrite `model` for that wildcard. So each vLLM gets a second served name: `--served-model-name <real-name> unknown`.
     - vLLM accepts any of its served names (`vllm/entrypoints/openai/models/serving.py`, `is_base_model`).
     - It reports the first name in its reply.
     - SMG reads only the first entry of `/v1/models`, so the gateway still lists only the real names.
   - f3 takes its no-preference name from `providers.json`, so f3 changes `auto` to `unknown` there.
   - `--model-alias auto=...` cannot do this, because an alias maps to exactly one model (`registry.rs` L2187-2240).
3. **Met** (default policy `cache_aware`).
   - It keeps a character radix tree per model id. A radix tree is a prefix tree that merges shared prefixes.
   - The tree is built over the message text (`crates/protocols/src/chat.rs` L807-864, `policies/cache_aware.rs`).
   - Wildcard requests share one tree keyed `"unknown"` that spans both servers. So a multi-step agent call with no preference keeps landing on the server that already holds its prefix.
   - No header is needed.
   - Tool definitions are not part of the text. That is fine, because they do not differ between steps.
   - Set `--balance-abs-threshold` low, for example 4. The default of 64 never trips at our concurrency of 6 to 8 (`main.rs` L283-288).
   - What would prove this wrong: two idle-time no-preference requests with the same long prefix landing on different servers.
4. **Met.**
   - It polls each worker's `/metrics` every `--load-monitor-interval` (default 10 s, can be lowered). It reads `vllm:num_requests_waiting`, `vllm:num_requests_running` and `vllm:kv_cache_usage_perc` (`worker/monitor.rs` L665-767).
   - `cache_aware` and `power_of_two` score expected wait from the waiting queue and KV pressure (`policies/least_load.rs` L24-60, L203-276). Between polls, they add the requests the gateway itself sent.
   - Limit: the score does not use free slots out of a known capacity (8 and 6). So "most room" is approximated by queue length and KV pressure.
   - The README claims each worker's KV-cache state is tracked. For HTTP workers that is a gateway-side estimate. Real KV events are gRPC-only (`worker/kv_event_monitor.rs` L174-182).
5. **Passthrough met. Counting priority-0 only needs code.**
   - The request is parsed and re-serialized, but a `#[serde(flatten)] other` catch-all keeps unknown fields (`crates/protocols/src/chat.rs` L389-391).
   - `priority` is stripped only when it is null or false (`crates/external_router/src/sglang_fields.rs`). An integer `priority` reaches vLLM unchanged.
   - SMG's own priority scheduler is not the same thing. It uses an `x-smg-priority` header that is not forwarded, and its flags exist only in the Rust binary, not the Docker image.
   - Counting only priority-0 requests needs a custom policy (see the last section).
6. **Met.**
   - Health checks: `GET /health` every 60 s. Three failures take a worker out and two successes bring it back. There is also a circuit breaker and retries before the first byte (`main.rs` L895-983).
   - Streaming: SSE bytes are relayed chunk by chunk without parsing, so tool-call deltas are untouched (`routers/http/router.rs` L1211-1326).
7. **Met.**
   - The Docker image `lightseekorg/smg` is multi-arch. Its registry manifest lists linux/arm64 (`.github/workflows/release-docker.yml` L113-120). pip `smg` has aarch64 wheels.
   - No database or etcd is needed; history storage defaults to memory.
   - About 560 stars, but it inherits the SGLang gateway's history. Releases come every 2 to 4 weeks (v1.7.0 2026-06-29 to v1.11.0 2026-09-24), with commits daily.

## vLLM production-stack router (vllm-project/production-stack, `src/vllm_router`)

1. **Met with configuration.**
   - Flags: `--service-discovery static --static-backends ... --static-models ...`.
   - `/v1/models` lists both models (`routers/main_router.py` L129-176).
2. **Needs code.**
   - Named models are filtered correctly (`services/request_service/request.py` L540-546).
   - `auto` gets a 404 (L566-575).
   - Static aliases rewrite `model`, but each alias maps to a single model (L516-520). Nothing picks across models.
3. **Met for named models only** (`--routing-logic prefixaware`).
   - It uses a hash trie over the message text in 128-character chunks, with no eviction (`routing_logic.py` L833-924). No header is needed.
   - It never sees a cross-model choice, because of item 2.
4. **Needs code.**
   - It scrapes vLLM `/metrics` every 30 s (`stats/engine_stats.py`), but no routing logic reads the result.
   - `loadaware` and `kvaware` need LMCache.
   - The `priority` logic uses the router's own in-flight count.
5. **Passthrough met.** The raw body bytes are forwarded (`request.py` L326-331, L436).
   - Exception: `--routing-logic priority` rewrites `priority` into the body.
   - Counting priority-0 only would take about 20 to 40 lines of Python in `PriorityRouter`.
6. **Met with configuration.**
   - Health checks need `--static-backend-health-checks`, which sends a real dummy chat request every 60 s.
   - Streaming passes chunks through as they arrive (`request.py` L341-351).
7. **Partly met.**
   - The published image `ghcr.io/vllm-project/production-stack/router` is amd64 only; its registry manifest has no arm64. We would build it ourselves (`docker/Dockerfile`).
   - About 2,660 stars, daily commits on the router. The helm chart is at 0.1.13 (2026-09-29).
   - The docs lag the code. The README lists only round robin and session, while the code has eight logics.

## vllm-project/router (Rust fork of sgl-router, v0.1.15)

1. **Not met.**
   - Two models need `--enable-igw` and each worker registered by hand through `POST /workers` with its `model_id`. Discovery calls SGLang's `/get_server_info` (`src/routers/router_manager.rs` L160-180, L325-341).
   - In this mode `/v1/models` returns a non-OpenAI shape (L522-538).
2. **Not met.** `auto` ends in a 503 after retries. There is no rewrite.
3. **Not met for chat.** The routing text for chat is only a session id or an empty string, so `cache_aware` degrades to least in-flight (`src/protocols/spec.rs` L559-567). Its docs claim otherwise.
4. **Not met.**
   - `power_of_two` polls SGLang's `/get_load`, so against vLLM it is effectively random (`router.rs` L1916-2046).
   - Only the opt-in "program scheduling" reads vLLM `/metrics`.
5. **Passthrough met** through a flatten catch-all. But re-serialization drops some fields: tool `strict`, the `developer` role, and some content types (`spec.rs`).
6. **Met.** Health checks on `/health`; SSE passed chunk by chunk.
7. **Met.**
   - `vllm/vllm-router` is multi-arch, and aarch64 wheels exist.
   - About 460 stars. The last release was 2026-07-13.

## SGLang in-tree gateway (sgl-project/sglang `sgl-model-gateway`, sglang-router 0.3.2)

This copy is superseded by SMG. Its last PyPI release was 2026-01-15, and its core types now come from SMG crates. Its `power_of_two` polls SGLang's `/v1/loads`. Use SMG instead.

## LiteLLM proxy (BerriAI/litellm, v1.104.0)

1. **Met.** `/v1/models` lists each `model_name` (`litellm/proxy/proxy_server.py` L11667).
2. **Met with configuration.**
   - A model group `auto` holds both vLLM deployments. Each deployment gets its own `litellm_params.model` (`litellm/router.py` L3816-3881).
   - Catch: load counters are kept per group. Traffic that names a model directly is not counted when `auto` chooses (`router_strategy/least_busy.py` L49-50).
3. **Not met.**
   - The `prompt_caching` check only hashes up to `cache_control` markers, which OpenAI clients do not send (`router_utils/prompt_caching_cache.py` L141-196).
   - Session affinity needs a session header.
4. **Not met.** No strategy reads server metrics. `least-busy` is the proxy's own count.
5. **Needs code or a workaround.**
   - A top-level integer `priority` is consumed by LiteLLM's own scheduler and not forwarded (`router.py` L2913-2924, L4523-4567).
   - Nesting it in `extra_body` probably works. That is untested.
6. **Partly met.**
   - Background health checks exist but steer routing only with `enable_health_check_routing`.
   - Streams are rebuilt chunk by chunk through LiteLLM's own types, not passed through (`litellm_core_utils/streaming_handler.py`). It also edits tool schemas for `hosted_vllm`.
7. **Met.**
   - The image `ghcr.io/berriai/litellm` has arm64. No database is needed, but a master key is required.
   - About 60,000 stars, releases several times a week.

## llm-d router (llm-d/llm-d-router, formerly llm-d-inference-scheduler, v0.11.0) and Gateway API Inference Extension (v1.6.2)

The inference extension no longer contains the scheduler. It moved to llm-d-router; the extension repo keeps the API and a round-robin reference (`README.md`).

1. **Not met.** One pool serves one base model, and the source has no model filter (`docs/architecture.md`). Two models need two schedulers plus Envoy routing on a header.
2. **Not met.** Model rewrite needs Kubernetes objects.
3. **Met within one model.** There is a `prefix-cache-scorer`.
4. **Met.** Scorers read vLLM `/metrics` waiting count and KV usage.
5. **Not met without Kubernetes.** Priority comes from InferenceObjective objects, which file-discovery mode does not load (`docs/discovery.md`).
6. **Met.** Responses go through Envoy.
7. **Partly met.**
   - It runs without Kubernetes in file-discovery mode, but always as two processes, the scheduler plus Envoy (ext_proc only). There is no compose example.
   - Images are multi-arch.
   - About 380 stars (the inference extension has about 780), with monthly releases.

## NVIDIA Dynamo (ai-dynamo/dynamo, v1.5.1)

**Not a fit.**
- The frontend tokenizes requests itself and talks only to workers launched as `python -m dynamo.vllm`. It cannot front a stock `vllm serve` over HTTP (`docs/fern/pages/use-cases/tool-calling-and-reasoning/overview.mdx`).
- Across two boxes, discovery needs etcd.
- It does have KV-event routing, multiple models, priority (`nvext.agent_hints.priority`) and arm64 images.
- About 8,200 stars, releases every few weeks.

## vLLM semantic router (vllm-project/semantic-router, v0.4.0)

**Not a fit for load or prefix.**
- It does pick a model for `auto` (or `MoM`) and rewrites `model` (`src/semantic-router/pkg/extproc/processor_req_body_routing.go` L242). But it picks by request content, and its load factor is its own in-flight count.
- It runs as one container (`vllm-sr serve`, standalone gateway mode).
- DGX Spark arm64 is "Experimental, not qualified" (`website/docs/installation/support-matrix.md`).
- About 6,000 stars.

## Code we would still write

With SMG, the setup needs no code. It needs:
- f3's no-preference name set to `unknown` in `providers.json`;
- `unknown` added as a second `--served-model-name` on both vLLM servers;
- SMG started with the two worker URLs, `--policy cache_aware`, a low `--balance-abs-threshold` and a short `--load-monitor-interval`.

Code is needed only for the "ideally" part of requirement 5, and it also fixes the free-slots limit of requirement 4. It is one custom SMG policy, about 100 to 150 lines of Rust:

1. Add a `priority()` reader for `other["priority"]` on the request trait (`crates/protocols/src/common.rs`, `GenerationRequest`).
2. Carry it in the selection input (`model_gateway/src/policies/mod.rs`, `SelectWorkerInfo`).
3. Write a policy beside `policies/cache_aware.rs`.
   - It keeps a per-worker count of in-flight requests with priority 0 (or no priority).
   - It increments the count where the load guard is taken (`routers/http/router.rs` L550-555) and decrements it on completion.
   - It judges room as each worker's capacity (8 or 6, from a worker label) minus that count. Ties and prefix matches go through the existing radix tree.
   - It ignores the polled vLLM gauges, which count every priority.

We would then build our own arm64 image from the fork (`docker/Dockerfile`) and carry the patch forward on each SMG release.

A smaller patch is an alternative to the second served name: set `model` to the chosen worker's model when the request names `unknown`, in `serialize_request_body` (`model_gateway/src/routers/http/request_body.rs` L41-80). That is about 10 lines.
