# Run records

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One run, as its logs show it: `logs`, the path of the run's logs; `files`, what they hold, with
sizes and times; `start` and `end`; `grades`, the ids of the run grades given to the run.
`S/src/record.sh` writes each record from the logs. A run S made with the layer's run command
adds `run_by_s`: the version, the command, the run kind, the output's path, the times and the exit
code. A project may add what its own logs show, such as `versions`, `use_case`, `trace`, `outcome`
and `cost`. Status: `complete` or `abandoned`. (MLflow runs, OpenTelemetry's GenAI agent spans,
SLSA provenance, and Anthropic's split between transcript and outcome.)
