#!/usr/bin/env bash
# Gate run: runs one command gate of a change, once, and records the run, so that step.sh can
# decide the gate from the record alone. The spec is shared/S/specs/step.md, "Changes, their kinds
# and their checks".
#
#   S/src/gate-run.sh <layer root> <change> <gate name>
#
# The command comes from <layer>/S/data/proposals/<change>.json, so what runs is the proposal's
# gate and nothing else. One record per run goes to the step's gates.jsonl, and the output to its
# gates/ folder. The exit code is the command's.
set -euo pipefail

P=$(cd "${1:?usage: gate-run.sh <layer root> <change> <gate name>}" && pwd)
C=${2:?usage: gate-run.sh <layer root> <change> <gate name>}
G=${3:?usage: gate-run.sh <layer root> <change> <gate name>}

command -v jq >/dev/null || { echo "gate-run: needs jq" >&2; exit 2; }
PROP="$P/S/data/proposals/$C.json"
[ -f "$PROP" ] || { echo "gate-run: no proposal at $PROP" >&2; exit 2; }
gate=$(jq -c --arg g "$G" '[.gates[]? | select(.name == $g)][0] // empty' "$PROP")
[ -n "$gate" ] || { echo "gate-run: $C has no gate \"$G\"" >&2; exit 2; }
cmd=$(jq -r '.command // ""' <<< "$gate")
[ -n "$cmd" ] || { echo "gate-run: \"$G\" is a prompt gate; the code reviewer judges it" >&2; exit 2; }
dir=$(jq -r '.dir // "."' <<< "$gate")

# The step's log folder: the one step.sh names, or else the latest step.
LOG=${S_STEP_LOG:-"$P/S/steps/$(ls -1 "$P/S/steps" 2>/dev/null | tail -1)"}
[ -d "$LOG" ] || { echo "gate-run: no step log folder in $P/S/steps" >&2; exit 2; }
mkdir -p "$LOG/gates"

# The code the gate runs on: HEAD, and whether the work tree holds anything else. S's own records
# (S/data/, S/steps/, S/outbox/) do not count: the roles write them during the step.
commit=$(git -C "$P" rev-parse HEAD)
tree=$(git -C "$P" rev-parse 'HEAD^{tree}')
clean=true
[ -z "$(git -C "$P" status --porcelain -- . ':!S/data' ':!S/steps' ':!S/outbox')" ] || clean=false

out="$LOG/gates/$C-${G//[^A-Za-z0-9._-]/_}-$(date +%Y%m%dT%H%M%S).log"
start=$(date +%FT%T)
set +e; (cd "$P/$dir" && bash -c "$cmd") > "$out" 2>&1; code=$?; set -e
end=$(date +%FT%T)

jq -nc --arg change "$C" --arg gate "$G" --arg command "$cmd" --arg commit "$commit" \
  --arg tree "$tree" --argjson clean "$clean" --argjson exit "$code" --arg start "$start" \
  --arg end "$end" --arg output "${out#"$P/"}" \
  '{change: $change, gate: $gate, command: $command, commit: $commit, tree: $tree,
    clean: $clean, exit: $exit, start: $start, end: $end, output: $output}' >> "$LOG/gates.jsonl"

tail -n 20 "$out"
note=""; [ "$clean" = true ] || note=", on a work tree with uncommitted changes, so it counts for nothing"
echo "gate-run: $C, gate \"$G\": exit $code$note; recorded in ${LOG#"$P/"}/gates.jsonl"
exit "$code"
