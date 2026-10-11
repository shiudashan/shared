# Run records

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One run: `versions`, of M and of S; `settings`; `use_case`, the id of the use case; `trace`,
every model call and tool call the run made, each with its start, end, inputs and outputs,
nested under the call that started it, as OpenTelemetry spans; `outcome`; `grades`, the ids of
the run grades given to the run; `cost`, with time, tokens and money. Status: `complete` or
`abandoned`. (MLflow runs, OpenTelemetry's GenAI agent spans, SLSA provenance, and Anthropic's
split between transcript and outcome.)
