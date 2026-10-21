#!/usr/bin/env bash
# Record: the program that records, so that models only judge. The spec is shared/S/specs/step.md,
# "Triggering and chaining", and data.md.
#
#   S/src/record.sh <layer root> seeds                     each seed a user gave becomes a use case
#   S/src/record.sh <layer root> runs                      records users' runs, and runs the version
#                                                          in use on each case it has not run
#   S/src/record.sh <layer root> new-case                  step 8: runs the first case never run;
#                                                          exit 3 when there is none
#   S/src/record.sh <layer root> entries <by> <types> <reply file>
#                                                          saves the entries a role's reply returns
#   S/src/record.sh <layer root> outbox <type> <lower entry | -> <reply file>
#                                                          saves a Send reply into the outbox
#
# The settings come from <layer>/S/src/chain.json: "seeds", the folder of seeds users gave (each
# item one seed); "user_runs", the folder of runs users made (each subfolder one run);
# "run_command", where {seed} stands for the use case's seed.
set -euo pipefail

P=$(cd "${1:?usage: record.sh <layer root> <mode> ...}" && pwd)
MODE=${2:?usage: record.sh <layer root> seeds | runs | new-case | entries | outbox}
command -v jq >/dev/null || { echo "record: needs jq" >&2; exit 2; }

CHAIN="$P/S/src/chain.json"
DATA="$P/S/data"
BY="user, recorded by S/src/record.sh"
setting() { jq -r --arg k "$1" '.[$k] // ""' "$CHAIN" 2>/dev/null || true; }
now() { date +%FT%T; }
norm() { local p=${1%/}; echo "${p#./}"; }   # a path without its trailing slash

# --- seeds -----------------------------------------------------------------------------------
seedtext() {  # seedtext <seed path>: the seed's text, word for word
  local s="$P/$1" f n
  if [ -f "$s" ]; then cat "$s"; return; fi
  n=$(find "$s" -maxdepth 1 -type f ! -name '.*' | sort | while read -r f; do grep -Iq . "$f" && echo "$f"; done)
  if [ "$(echo "$n" | grep -c .)" = 1 ]; then cat "$n"; return; fi
  for f in $n; do printf '== %s ==\n' "$(basename "$f")"; cat "$f"; echo; done
}
seeds() {
  local dir; dir=$(norm "$(setting seeds)")
  [ -n "$dir" ] && [ -d "$P/$dir" ] || { echo "record: no seeds folder in chain.json"; return 0; }
  mkdir -p "$DATA/use-cases"
  local known item id path f
  known=$(for f in "$DATA/use-cases"/*.json; do if [ -e "$f" ]; then jq -r '.seed // empty' "$f" 2>/dev/null || true; fi; done | sed 's|/$||')
  for item in "$P/$dir"/*; do
    [ -e "$item" ] || continue
    path="$dir/$(basename "$item")"
    grep -qxF "$path" <<< "$known" && continue
    id=$(basename "$item"); id=${id%.*}
    [ ! -e "$DATA/use-cases/$id.json" ] || id="$id-$(date +%s)"
    seedtext "$path" > "$DATA/use-cases/$id.json.text"
    jq -n --arg id "$id" --arg by "$BY" --arg seed "$path" --rawfile text "$DATA/use-cases/$id.json.text" \
      '{id: $id, by: $by, status: "active", upstream: "local", seed: $seed, seedtext: $text}' > "$DATA/use-cases/$id.json"
    rm -f "$DATA/use-cases/$id.json.text"
    echo "record: use case $id from $path"
  done
  # A use case whose seed is gone is retired.
  for f in "$DATA/use-cases"/*.json; do
    [ -e "$f" ] || continue
    path=$(jq -r 'select(.status == "active") | .seed // empty' "$f" 2>/dev/null | sed 's|/$||')
    case $path in "$dir"/*) ;; *) continue ;; esac
    [ -e "$P/$path" ] && continue
    jq --arg d "S/src/record.sh, $(now): the seed $path is gone" '.status = "retired" | .decided = $d' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    echo "record: use case $(basename "$f" .json) retired, its seed is gone"
  done
}

# --- runs ------------------------------------------------------------------------------------
version() { git -C "$P" describe --tags --always 2>/dev/null || echo unknown; }
step_log() { echo "${S_STEP_LOG:-$P/S/steps/$(ls -1 "$P/S/steps" 2>/dev/null | tail -1)}"; }
user_runs() {  # each run a user made, with no run record yet, becomes one
  local dir; dir=$(norm "$(setting user_runs)")
  [ -n "$dir" ] && [ -d "$P/$dir" ] || return 0
  local known run path id f
  known=$(for f in "$DATA/run-records"/*.json; do if [ -e "$f" ]; then jq -r '.run // empty' "$f" 2>/dev/null || true; fi; done | sed 's|/$||')
  for run in "$P/$dir"/*/; do
    [ -d "$run" ] || continue
    path="$dir/$(basename "$run")"
    grep -qxF "$path" <<< "$known" && continue
    id=$(basename "$run")
    [ ! -e "$DATA/run-records/$id.json" ] || continue
    (cd "$P" && find "$path" -type f ! -name '.*' -printf '%P\t%s\t%TY-%Tm-%TdT%TH:%TM:%TS\n' | sort) |
      jq -R -s 'split("\n") | map(select(. != "") | split("\t") | {path: .[0], bytes: (.[1] | tonumber), modified: .[2][0:19]})' |
      jq --arg id "$id" --arg by "user, recorded by S/src/record.sh" --arg run "$path/" \
        '{id: $id, by: $by, status: "complete", upstream: "local", run: $run, use_case: "", files: .}' > "$DATA/run-records/$id.json"
    echo "record: run record $id, a user's run in $path"
  done
}
run_case() {  # run_case <use case file>: runs the version in use on the case, and records the run
  local f=$1 cmd uc seed v log out start end code id
  cmd=$(setting run_command); [ -n "$cmd" ] || return 0
  uc=$(jq -r .id "$f"); seed=$(jq -r '.seed // ""' "$f"); v=$(version)
  cmd=${cmd//\{seed\}/$seed}
  log=$(step_log); mkdir -p "$log/runs"
  id="$uc-$(date +%Y%m%dT%H%M%S)"; out="$log/runs/$id.log"
  start=$(now)
  set +e; (cd "$P" && S_SEED="$seed" S_RUN_KIND="${S_RUN_KIND:-true}" bash -c "$cmd") > "$out" 2>&1; code=$?; set -e
  end=$(now)
  jq -n --arg id "$id" --arg by "user, run by S/src/record.sh" --arg uc "$uc" --arg v "$v" \
    --arg kind "${S_RUN_KIND:-true}" --arg cmd "$cmd" --arg seed "$seed" --arg out "${out#"$P/"}" \
    --arg start "$start" --arg end "$end" --argjson code "$code" \
    --argjson secs "$(( $(date -d "$end" +%s) - $(date -d "$start" +%s) ))" \
    '{id: $id, by: $by, status: (if $code == 0 then "complete" else "abandoned" end), upstream: "local",
      versions: {M: $v}, settings: {run_kind: $kind}, use_case: $uc,
      trace: {command: $cmd, seed: $seed, output: $out, start: $start, end: $end, exit: $code},
      outcome: "exit \($code)", grades: [], cost: {seconds: $secs}}' > "$DATA/run-records/$id.json"
  echo "record: run record $id, use case $uc on $v, exit $code"
}
has_run() {  # has_run <use case id> [<version>]: a run record of the case exists (of that version)
  local f
  for f in "$DATA/run-records"/*.json; do
    [ -e "$f" ] || continue
    jq -e --arg u "$1" --arg v "${2:-}" '.use_case == $u and ($v == "" or .versions.M == $v)' "$f" >/dev/null 2>&1 && return 0
  done
  return 1
}
active_cases() { for f in "$DATA/use-cases"/*.json; do [ -e "$f" ] && [ "$(jq -r .status "$f" 2>/dev/null)" = active ] && echo "$f"; done; true; }
runs() {
  mkdir -p "$DATA/run-records"
  user_runs
  [ -n "$(setting run_command)" ] || { echo "record: no run command in chain.json; no runs made"; return 0; }
  local v f; v=$(version)
  for f in $(active_cases); do has_run "$(jq -r .id "$f")" "$v" || run_case "$f"; done
}
new_case() {
  seeds; mkdir -p "$DATA/run-records"
  local f
  for f in $(active_cases); do
    has_run "$(jq -r .id "$f")" && continue
    run_case "$f"; return 0
  done
  echo "the step needs a new use case from a user: every use case has been run"
  exit 3
}

# --- entries from replies --------------------------------------------------------------------
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

# --- the outbox, from a Send reply -----------------------------------------------------------
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
  seeds) seeds ;;
  runs) runs ;;
  new-case) new_case ;;
  entries) entries "${3:?by}" "${4-}" "${5:?reply file}" ;;
  outbox) outbox "${3:?type}" "${4:?lower entry}" "${5:?reply file}" ;;
  *) echo "record: unknown mode $MODE" >&2; exit 2 ;;
esac
