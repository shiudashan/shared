#!/usr/bin/env bash
# Record: the program that records, so that models only judge. The spec is shared/S/specs/step.md,
# "Triggering and chaining", and data.md.
#
#   S/src/record.sh <layer root> runs        runs the run command, if the layer has one and this
#                                            version has no run of S's yet; then records each new
#                                            run found in the logs
#   S/src/record.sh <layer root> new-logs    step 8: records new runs from the logs; exit 3 when
#                                            users have made none since the last record
#   S/src/record.sh <layer root> entries <by> <types> <reply file>
#                                            saves the entries a role's reply returns
#   S/src/record.sh <layer root> outbox <type> <lower entry | -> <reply file>
#                                            saves a Send reply into the outbox
#
# The settings come from <layer>/S/src/chain.json: "logs", the folder where the program's logs
# land, each item in it one run; "run_command", a command that uses the program once more, such as
# a replay, whose logs land there too; "extract", a command of the layer's that draws use cases or
# more out of the logs. Each may be empty.
set -euo pipefail

P=$(cd "${1:?usage: record.sh <layer root> <mode> ...}" && pwd)
MODE=${2:?usage: record.sh <layer root> runs | new-logs | entries | outbox}
command -v jq >/dev/null || { echo "record: needs jq" >&2; exit 2; }

CHAIN="$P/S/src/chain.json"
DATA="$P/S/data"
setting() { jq -r --arg k "$1" '.[$k] // ""' "$CHAIN" 2>/dev/null || true; }
now() { date +%FT%T; }
version() { git -C "$P" describe --tags --always 2>/dev/null || echo unknown; }
step_log() { echo "${S_STEP_LOG:-$P/S/steps/$(ls -1 "$P/S/steps" 2>/dev/null | tail -1)}"; }

# --- runs, from the logs -----------------------------------------------------------------------
LOGS=$(setting logs); LOGS=${LOGS%/}; LOGS=${LOGS#./}
items() {  # each item in the logs folder: one run
  [ -n "$LOGS" ] && [ -d "$P/$LOGS" ] || return 0
  local i; for i in "$P/$LOGS"/*; do if [ -e "$i" ]; then echo "$LOGS/$(basename "$i")"; fi; done
}
recorded() {  # the logs every run record points to
  local f; for f in "$DATA/run-records"/*.json; do if [ -e "$f" ]; then jq -r '.logs // empty' "$f" 2>/dev/null || true; fi; done
}
NEW_RUNS=0
record_logs() {  # record_logs <by> <extra json>: a run record for each item of the logs not yet recorded
  local by=$1 extra=$2 known item id
  NEW_RUNS=0; mkdir -p "$DATA/run-records"; known=$(recorded)
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    if grep -qxF "$item" <<< "$known"; then continue; fi
    id=$(basename "$item"); id=${id%.*}
    [ ! -e "$DATA/run-records/$id.json" ] || id="$id-$(date +%s)"
    (cd "$P" && find "$item" -type f ! -name '.*' -printf '%p\t%s\t%TY-%Tm-%TdT%TH:%TM:%TS\n' | sort) |
      jq -R -s 'split("\n") | map(select(. != "") | split("\t") | {path: .[0], bytes: (.[1] | tonumber), modified: .[2][0:19]})' |
      jq --arg id "$id" --arg by "$by" --arg logs "$item" --argjson extra "$extra" \
        '{id: $id, by: $by, status: "complete", upstream: "local", logs: $logs, files: .,
          start: (map(.modified) | min // ""), end: (map(.modified) | max // ""), grades: []} + $extra
        | if (.run_by_s.exit // 0) != 0 then .status = "abandoned" else . end' \
        > "$DATA/run-records/$id.json"
    echo "record: run record $id, from $item"; NEW_RUNS=$((NEW_RUNS + 1))
  done < <(items)
}
s_ran() {  # s_ran <version>: S's run command already ran on that version
  local f; for f in "$DATA/run-records"/*.json; do
    if [ -e "$f" ] && jq -e --arg v "$1" '.run_by_s.version == $v' "$f" >/dev/null 2>&1; then return 0; fi
  done; return 1
}
run_command() {  # uses the program once more with the layer's run command; its logs are S's runs
  local cmd v out start end code by_s id
  cmd=$(setting run_command); v=$(version)
  [ -n "$cmd" ] || { echo "record: no run command in chain.json; S makes no runs"; return 0; }
  if s_ran "$v"; then echo "record: S has run $v already"; return 0; fi
  record_logs "a user" '{}'   # logs already there are users'
  mkdir -p "$(step_log)/runs"; out="$(step_log)/runs/run-$(date +%Y%m%dT%H%M%S).log"
  start=$(now)
  set +e; (cd "$P" && S_RUN_KIND="${S_RUN_KIND:-true}" bash -c "$cmd") > "$out" 2>&1; code=$?; set -e
  end=$(now)
  by_s=$(jq -nc --arg v "$v" --arg cmd "$cmd" --arg kind "${S_RUN_KIND:-true}" --arg out "${out#"$P/"}" \
    --arg s "$start" --arg e "$end" --argjson c "$code" \
    '{run_by_s: {version: $v, command: $cmd, kind: $kind, output: $out, start: $s, end: $e, exit: $c}}')
  record_logs "S's run command" "$by_s"
  if [ "$NEW_RUNS" = 0 ]; then   # the command left no logs: its own output is the run's log
    id="run-$v-$(date +%Y%m%dT%H%M%S)"
    jq -n --arg id "$id" --argjson b "$by_s" \
      '{id: $id, by: "S'"'"'s run command", status: (if $b.run_by_s.exit == 0 then "complete" else "abandoned" end),
        upstream: "local", logs: $b.run_by_s.output, start: $b.run_by_s.start, end: $b.run_by_s.end, grades: []} + $b' \
      > "$DATA/run-records/$id.json"
    echo "record: run record $id, the run command's own output, exit $code"
  fi
}
extract() {  # the layer's own program draws more out of the logs, such as use cases
  local cmd; cmd=$(setting extract)
  if [ -n "$cmd" ]; then (cd "$P" && S_LAYER="$P" bash -c "$cmd"); fi
}
runs() { run_command; record_logs "a user" '{}'; extract; }
new_logs() {
  record_logs "a user" '{}'
  if [ "$NEW_RUNS" = 0 ]; then echo "the step waits for new logs from users of the version in use"; exit 3; fi
  extract
}

# --- entries from replies ----------------------------------------------------------------------
# A role returns its entries in its reply's "entries", each with its "type" and "id"; the program
# writes them. Revising an entry keeps what only the developer sets (decided, reason, earlier).
entries() {
  local by=$1 types=" $2 " reply=$3 e type id dest
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    type=$(jq -r '.type // ""' <<< "$e"); id=$(jq -r '.id // ""' <<< "$e")
    if [[ $types != *" $type "* ]]; then echo "record: refused an entry of type \"$type\": not one this hand-off writes" >&2; continue; fi
    if ! [[ $id =~ ^[A-Za-z0-9._-]+$ ]]; then echo "record: refused a $type entry with the id \"$id\"" >&2; continue; fi
    mkdir -p "$DATA/$type"; dest="$DATA/$type/$id.json"
    if [ -e "$dest" ]; then
      jq --slurpfile o "$dest" --arg by "$by" \
        '($o[0] | with_entries(select(.key == "decided" or .key == "reason" or .key == "earlier"))) + del(.type) | .by //= $by | .upstream //= "local"' <<< "$e" > "$dest.tmp"
    else
      jq --arg by "$by" 'del(.type) | .by //= $by | .upstream //= "local"' <<< "$e" > "$dest.tmp"
    fi
    mv "$dest.tmp" "$dest"; echo "S/data/$type/$id.json"
  done < <(jq -c '.entries[]?' "$reply" 2>/dev/null)
}

# --- the outbox, from a Send reply -------------------------------------------------------------
# The sending agent replies with the revised entry; it keeps the lower entry's id, by and status.
outbox() {
  local type=$1 lower=$2 reply=$3 json id
  json=$(perl -0777 -ne 'print $1 if /(\{.*\})/s' "$reply" | jq -c . 2>/dev/null || true)
  [ -n "$json" ] && [ "$json" != "{}" ] || { echo "record: the Send reply held no entry" >&2; return 1; }
  mkdir -p "$P/S/outbox/$type"
  if [ "$lower" = - ]; then   # an offer of the layer's own, such as the coder's program
    id=$(jq -r '.id // ""' <<< "$json")
    [[ $id =~ ^[A-Za-z0-9._-]+$ ]] || { echo "record: the offer has no usable id" >&2; return 1; }
    printf '%s\n' "$json" | jq . > "$P/S/outbox/$type/$id.json"
  else
    id=$(jq -r .id "$lower")
    jq --slurpfile l "$lower" '. + {id: $l[0].id, by: $l[0].by, status: $l[0].status}' <<< "$json" > "$P/S/outbox/$type/$id.json"
  fi
  echo "S/outbox/$type/$id.json"
}

case $MODE in
  runs) runs ;;
  new-logs) new_logs ;;
  entries) entries "${3:?by}" "${4-}" "${5:?reply file}" ;;
  outbox) outbox "${3:?type}" "${4:?lower entry}" "${5:?reply file}" ;;
  *) echo "record: unknown mode $MODE" >&2; exit 2 ;;
esac
