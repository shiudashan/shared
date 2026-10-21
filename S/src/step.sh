#!/usr/bin/env bash
# Step: plays one step of S on a layer, hand-off by hand-off. The spec is shared/S/specs/step.md,
# "Triggering and chaining".
#
#   S/src/step.sh <layer root>                       starts a new step
#   S/src/step.sh <layer root> --from <hand-off>     resumes the latest step at that hand-off
#
# The chain is <layer>/S/src/chain.json. For each hand-off, step.sh gives the hand-off's role the
# global prompt (<layer>/S/src/agents/global.md), then its instructions
# (<layer>/S/src/agents/<role>/prompt.md, up to its first "## Send"), its settings,
# the task, and the step so far, in one `claude -p` call in the layer root. The role writes its
# entries into <layer>/S/data/<type>/. step.sh records the hand-off in the step's log,
# <layer>/S/steps/<step id>/. When the step completes, step.sh holds the submit pass: each role
# that wrote entries in the step retags them, with the whole step in view, and the role's sending
# agent revises each candidate into <layer>/S/outbox/<type>/. step.sh stops at a hand-off that waits
# for a person, and prints how to resume.
#
# STEP_NO_CLAUDE=1 skips the `claude -p` calls and records what each would have done. Tests use it.
#
# The whole script is one function, so bash reads all of it before it runs.

main() {
set -euo pipefail

P=$(cd "${1:?usage: step.sh <layer root> [--from <hand-off>]}" && pwd)
FROM=""
[ "${2:-}" = "--from" ] && FROM=${3:?usage: step.sh <layer root> --from <hand-off>}

# --- Settings the layer customises -------------------------------------------------------
CHAIN="$P/S/src/chain.json"   # the layer's chain
AGENTS_DIR="S/src/agents"
DATA_DIR="S/data"
OUTBOX_DIR="S/outbox"
STEPS_DIR="S/steps"           # one log folder per step
# The words in each role's "## Send" heading, per type (as in upstream.sh).
SEND_WORDS=(
  "use-cases|use case" "run-grades|run grade" "decisions|decision" "run-reviews|run review"
  "proposals|proposal" "proposal-reviews|proposal review" "code-reviews|code review"
)
# -------------------------------------------------------------------------------------------

command -v jq >/dev/null || { echo "step: needs jq" >&2; exit 2; }
[ -f "$CHAIN" ] || { echo "step: no chain at $CHAIN" >&2; exit 2; }
GLOBAL="$P/$AGENTS_DIR/global.md"   # the rules every role shares
[ -f "$GLOBAL" ] || { echo "step: no global prompt at $GLOBAL" >&2; exit 2; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

N=$(jq '.handoffs | length' "$CHAIN")
ROUNDS=$(jq -r '.rounds // 1' "$CHAIN")
RUN_COMMAND=$(jq -r '.run_command // ""' "$CHAIN")
LEG=$(jq -r '.leg // ""' "$CHAIN")
LAYER=$(jq -r '.layer // ""' "$CHAIN")

if [ -z "$FROM" ]; then
  ID=$(date +%Y-%m-%d-%H%M%S); START=0
else
  ID=$(ls -1 "$P/$STEPS_DIR" 2>/dev/null | tail -1)
  [ -n "$ID" ] || { echo "step: no step to resume in $P/$STEPS_DIR" >&2; exit 2; }
  START=$(jq --arg n "$FROM" '[.handoffs[].name] | index($n) // -1' "$CHAIN")
  [ "$FROM" != end ] || START=$N        # "end": past the last hand-off, to the step's end
  [ "$START" -ge 0 ] || { echo "step: no hand-off \"$FROM\" in $CHAIN" >&2; exit 2; }
fi
LOG="$P/$STEPS_DIR/$ID"; mkdir -p "$LOG"
# The branch the step started on: the coder merges released changes into it.
[ -f "$LOG/branch" ] || git -C "$P" rev-parse --abbrev-ref HEAD > "$LOG/branch" 2>/dev/null || echo "" > "$LOG/branch"
BRANCH=$(cat "$LOG/branch")
echo "step: $ID in $P${FROM:+, from $FROM}${BRANCH:+, on branch $BRANCH}"

record() {  # record <hand-off> <event> <detail>: one line of the step's log
  jq -nc --arg h "$1" --arg e "$2" --arg d "$3" --arg t "$(date +%FT%T)" \
    '{at: $t, handoff: $h, event: $e, detail: $d}' >> "$LOG/log.jsonl"
  echo "  $1: $2${3:+ ($3)}"
}
fresh() {  # fresh <type>: entries of <type> written since the last completed step began; on a
  # layer's first step, every entry that is not a made-up sample
  local t=$1 prev="" d
  for d in $(ls -1 "$P/$STEPS_DIR" 2>/dev/null | grep -vx "$ID"); do
    grep -q '"step complete"' "$P/$STEPS_DIR/$d/log.jsonl" 2>/dev/null && prev=$d
  done
  if [ -n "$prev" ]; then find "$P/$DATA_DIR/$t" -name '*.json' -newer "$P/$STEPS_DIR/$prev/branch" 2>/dev/null
  else for f in "$P/$DATA_DIR/$t"/*.json; do [ -e "$f" ] && [ "$(jq -r '.made_up // false' "$f" 2>/dev/null)" != true ] && echo "$f"; done; fi
}
section() {  # section <prompt.md> <send words>: the global prompt, then the role's instructions,
  # or its "## Send" section
  cat "$GLOBAL"
  if [ -z "$2" ]; then awk '/^## Send/ {exit} {print}' "$1"
  else awk -v w="$2" '/^## / { on = ($0 ~ /^## Send/ && index($0, w) > 0) } on' "$1"; fi
}
entries() {  # entries <types...>: every entry file of those types, with its checksum, one per line,
  # so an entry a role revises in place counts as written, like a new one
  local t f; for t in "$@"; do for f in "$P/$DATA_DIR/$t"/*.json; do if [ -e "$f" ]; then echo "$f $(cksum < "$f" | tr ' ' '-')"; fi; done; done | sort
}
ask() {  # ask <hand-off index> <message file> <reply file>
  local h=$1 role model flags
  role=$(jq -r ".handoffs[$h].role" "$CHAIN")
  model=$(jq -r '.model // "no preference"' "$P/$AGENTS_DIR/$role/settings.json" 2>/dev/null || echo "no preference")
  flags=(); while IFS= read -r f; do flags+=("$f"); done < <(jq -r "(.handoffs[$h].claude_flags // .claude_flags // [])[]" "$CHAIN")
  [ "$model" = "no preference" ] || flags+=(--model "$model")
  if [ "${STEP_NO_CLAUDE:-}" = 1 ]; then echo '{"skipped": "STEP_NO_CLAUDE=1"}' > "$3"; return 0; fi
  (cd "$P" && S_RUN_KIND="${RUN_KIND:-}" S_STEP_LOG="$LOG" claude -p "${flags[@]}" < "$2") > "$3"
}

# Gates (step.md, "Changes, their kinds and their checks"). The program decides each command gate
# from the records S/src/gate-run.sh wrote, and reruns nothing; the code reviewer judges the prompt
# gates. Each verdict goes to the step's log and to $LOG/verdicts.jsonl; a change's latest verdict
# counts.
verdict() {  # verdict <hand-off> <change> <commit> <passed|failed> <reason>
  jq -nc --arg c "$2" --arg m "$3" --arg v "$4" --arg r "$5" '{change: $c, commit: $m, verdict: $v, reason: $r}' >> "$LOG/verdicts.jsonl"
  record "$1" "change $4" "$2${5:+: $5}"
}
check_gates() {  # check_gates <hand-off> <reply json>: each change the coder passed, by its records
  local c id commit prop tree g gname cmd rec reason
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    id=$(jq -r .change <<< "$c"); commit=$(jq -r '.commit // ""' <<< "$c")
    prop="$P/$DATA_DIR/proposals/$id.json"; reason=""
    if [ ! -f "$prop" ]; then reason="no proposal $id"
    elif [ "$(jq '[.gates[]?] | length' "$prop")" = 0 ]; then reason="no gate commands"
    elif ! tree=$(git -C "$P" rev-parse --verify -q "$commit^{tree}"); then reason="no commit \"$commit\""
    else
      while IFS= read -r g; do
        gname=$(jq -r .name <<< "$g"); cmd=$(jq -r .command <<< "$g")
        rec=$(jq -c --arg c "$id" --arg g "$gname" 'select(.change == $c and .gate == $g)' "$LOG/gates.jsonl" 2>/dev/null | tail -1)
        if [ -z "$rec" ]; then reason="gate \"$gname\" never run"
        elif [ "$(jq -r .command <<< "$rec")" != "$cmd" ]; then reason="gate \"$gname\": command differs from the proposal"
        elif [ "$(jq -r .tree <<< "$rec")" != "$tree" ] || [ "$(jq -r .clean <<< "$rec")" != true ]; then reason="gate \"$gname\" ran on other code"
        elif [ "$(jq -r .exit <<< "$rec")" != 0 ]; then reason="gate \"$gname\": exit $(jq -r .exit <<< "$rec")"
        fi
        [ -z "$reason" ] || break
      done < <(jq -c '.gates[] | select(.command)' "$prop")
    fi
    if [ -z "$reason" ]; then verdict "$1" "$id" "$commit" passed ""; else verdict "$1" "$id" "$commit" failed "$reason"; fi
  done < <(jq -c '(.changes // [.]) | map(select(.change and .result == "passed"))[]' <<< "$2")
}
check_prompt_gates() {  # check_prompt_gates <hand-off> <new entries>: a passing verdict on each prompt gate
  local line id commit prop gname review v
  [ -s "$LOG/verdicts.jsonl" ] || return 0
  while IFS= read -r line; do
    id=$(jq -r .change <<< "$line"); commit=$(jq -r .commit <<< "$line")
    prop="$P/$DATA_DIR/proposals/$id.json"
    [ "$(jq '[.gates[]? | select(.prompt)] | length' "$prop" 2>/dev/null || echo 0)" != 0 ] || continue
    review=""; for f in $2; do
      case $f in */code-reviews/*) [ "$(jq -r '.change // ""' "$P/$f")" = "$id" ] && review="$P/$f" ;; esac
    done
    [ -n "$review" ] || { verdict "$1" "$id" "$commit" failed "no code review judged its prompt gates"; continue; }
    while IFS= read -r gname; do
      v=$(jq -r --arg g "$gname" '[.gates[]? | select(.name == $g)][0].verdict // "none"' "$review")
      [ "$v" = pass ] || { verdict "$1" "$id" "$commit" failed "prompt gate \"$gname\": verdict $v"; continue 2; }
    done < <(jq -r '.gates[] | select(.prompt) | .name' "$prop")
    verdict "$1" "$id" "$commit" passed "prompt gates judged"
  done < <(jq -c -s 'group_by(.change) | map(last) | map(select(.verdict == "passed" and .reason == ""))[]' "$LOG/verdicts.jsonl")
}
check_merge() {  # check_merge <hand-off>: no change whose latest verdict failed is in the step's branch
  local id commit
  [ -s "$LOG/verdicts.jsonl" ] && [ -n "$BRANCH" ] || return 0
  while read -r id commit; do
    [ -n "$id" ] || continue
    if git -C "$P" merge-base --is-ancestor "$commit" "$BRANCH" 2>/dev/null; then
      record "$1" "merge included a failed change" "$id ($commit)"
      echo "step: the merge put $id ($commit), which failed its gates, into $BRANCH. Undo the merge, then resume with --from $1." >&2
      return 1
    fi
  done < <(jq -r -s 'group_by(.change) | map(last) | map(select(.verdict == "failed"))[] | "\(.change) \(.commit)"' "$LOG/verdicts.jsonl")
}

send() {  # send <hand-off index> <entry file>: the role's sending agent revises one candidate
  local h=$1 e=$2 role type words w
  role=$(jq -r ".handoffs[$h].role" "$CHAIN"); type=$(basename "$(dirname "$e")")
  for w in "${SEND_WORDS[@]}"; do [ "${w%%|*}" = "$type" ] && words=${w#*|}; done
  [ -n "${words:-}" ] || return 0
  {
    section "$P/$AGENTS_DIR/$role/prompt.md" "$words"
    echo; echo "Lower layer: $LAYER"; echo "Leg: $LEG"; echo; echo "Entry:"; cat "$e"
  } > "$TMP/send"
  if ask "$h" "$TMP/send" "$TMP/send-reply"; then record "$(jq -r ".handoffs[$h].name" "$CHAIN")" "sent" "$type/$(basename "$e")"
  else record "$(jq -r ".handoffs[$h].name" "$CHAIN")" "send failed" "$type/$(basename "$e")"; fi
}

# The developer is consulted at the end of each step listed in chain.json's "consult" (S's
# steps, step.md); the step's last hand-off may be skipped, so the stop is on the step itself.
CONSULT=" $(jq -r '(.consult // []) | map(tostring) | join(" ")' "$CHAIN") "
step_of() { jq -r ".handoffs[$1].step | tostring" "$CHAIN"; }
CUR=$( [ "$START" -lt "$N" ] && step_of "$START" || echo "")
STEP_RAN="" STEP_NEW="" STEP_JUDGED="" STEP_NAMES="" LOOPED=""
step_end() {  # step_end <next hand-off name>: 0 when the step stops for the developer
  [ -n "$CUR" ] && [ -n "$STEP_RAN" ] && [[ $CONSULT == *" $CUR "* ]] || return 1
  local names redo
  names=$(echo $STEP_NAMES | sed 's/ /, /g')
  # A correction goes back to the first hand-off that does work among those the developer was shown.
  redo=$(jq -r --arg n "$STEP_NAMES" '($n | split(" ")) as $ran | [.handoffs[] | select(.name as $x | $ran | index($x)) | select((.records | not) and ((.writes // []) | length > 0)) | .name][0] // ""' "$CHAIN")
  jq -n --arg st "$CUR" --arg n "$names" --arg e "$STEP_NEW" --arg next "$1" --arg redo "$redo" \
    --arg j "$STEP_JUDGED" '{step: $st, handoffs: $n, entries: ($e | split(" ") | map(select(. != ""))), judged: ($j | split(" ") | map(select(. != ""))), next: $next, redo: $redo}' > "$LOG/gate"
  record "step $CUR" "waits for the developer" "${STEP_NEW:-no new entries}"
  echo "step: step $CUR ($names) is done and waits for the developer; its entries: ${STEP_NEW:-none}"
  return 0
}

h=$START; round=1
while [ "$h" -lt "$N" ]; do
  s_now=$(step_of "$h")
  if [ -z "$LOOPED" ] && [ "$s_now" != "$CUR" ]; then
    if step_end "$(jq -r ".handoffs[$h].name" "$CHAIN")"; then return 0; fi
    # Work of a step the developer is not consulted on is shown with the next step that is.
    if [[ $CONSULT == *" $CUR "* ]]; then STEP_RAN="" STEP_NEW="" STEP_JUDGED="" STEP_NAMES=""; fi
    CUR=$s_now
  fi
  LOOPED=""
  name=$(jq -r ".handoffs[$h].name" "$CHAIN")
  role=$(jq -r ".handoffs[$h].role" "$CHAIN")
  start=$(jq -r ".handoffs[$h].start // \"auto\"" "$CHAIN")
  run=$(jq -r ".handoffs[$h].run // \"\"" "$CHAIN")
  writes=(); while IFS= read -r w; do writes+=("$w"); done < <(jq -r ".handoffs[$h].writes[]" "$CHAIN")

  # A hand-off whose needed types gained no entry since the last completed step has nothing to
  # work on: none in this step, and none written between steps, such as the developer's own.
  needs=$(jq -r ".handoffs[$h].needs // [] | join(\" \")" "$CHAIN")
  if [ -n "$needs" ]; then
    got=""; for t in $needs; do
      grep -q "\"detail\":\"[^\"]*S/data/$t/" "$LOG/log.jsonl" 2>/dev/null && got=1
      [ -n "$got" ] || [ -z "$(fresh "$t")" ] || got=1
    done
    if [ -z "$got" ]; then record "$name" "skipped" "no new $needs since the last step"; h=$((h + 1)); continue; fi
  fi

  FROM=""

  # Runs: a layer with no run command makes none.
  RUN_KIND=""
  if [ -n "$run" ]; then
    if [ -z "$RUN_COMMAND" ]; then record "$name" "skipped" "no run command in chain.json"; h=$((h + 1)); continue; fi
    RUN_KIND=$run
  fi

  entries ${writes[@]+"${writes[@]}"} > "$TMP/before"
  {
    section "$P/$AGENTS_DIR/$role/prompt.md" ""
    echo
    echo "## Now"
    echo
    echo "You act as the $role at the hand-off \"$name\", step $(jq -r ".handoffs[$h].step" "$CHAIN") of S's step (S/specs/step.md), in the layer at $P. This step's id is $ID. The step started on the git branch \"$BRANCH\"."
    echo
    echo "Your task: $(jq -r ".handoffs[$h].do" "$CHAIN")"
    [ "$round" -eq 1 ] || echo "This is round $round of the propose-review loop."
    echo
    echo "Your settings: $(jq -c . "$P/$AGENTS_DIR/$role/settings.json" 2>/dev/null || echo '{}')"
    echo
    echo "The step so far, from $STEPS_DIR/$ID/log.jsonl; each earlier role's reply is in $STEPS_DIR/$ID/:"
    cat "$LOG/log.jsonl" 2>/dev/null || echo "(nothing yet)"
    echo
    if [ ${#writes[@]} -gt 0 ]; then
      echo "Write each entry you produce as one JSON file, $DATA_DIR/<type>/<entry id>.json, for the types: ${writes[*]}. Follow the format in $DATA_DIR/<type>/README.md and S/specs/data.md. Set \"by\" to \"$role\" with who plays it, and \"upstream\" to \"candidate\" when the entry could help an agent of any role in another component or project do its work better, or to \"local\" otherwise."
    fi
    [ -z "$RUN_KIND" ] || echo "The run command: $RUN_COMMAND. S_RUN_KIND=$RUN_KIND is set, so M.f logs as a $RUN_KIND run."
    if [ -s "$LOG/note" ]; then
      echo "The developer said, at this point of the step, in their own words: $(cat "$LOG/note")"
      echo "Take this into your work."
      mv "$LOG/note" "$LOG/note-read"
    fi
    echo "End your reply with the action's JSON, as your instructions give it. In it, list in \"used\" the ids of the entries in $DATA_DIR/ you relied on."
  } > "$TMP/message"

  record "$name" "starts" "the $role${RUN_KIND:+, $RUN_KIND runs}"
  reply="$LOG/$(printf '%02d' "$h")-$name-$round.reply"
  if ! ask "$h" "$TMP/message" "$reply"; then record "$name" "failed" "claude -p failed; resume with --from $name"; return 1; fi
  # The reply ends with its JSON, bare or in a code fence.
  json=$(perl -0777 -ne 'print $1 if /(\{.*\})\s*(?:```)?\s*$/s' "$reply" | jq -c . 2>/dev/null || true)
  [ -n "$json" ] || json='{}'

  entries ${writes[@]+"${writes[@]}"} > "$TMP/after"
  new=$(comm -13 "$TMP/before" "$TMP/after" | cut -d' ' -f1 | sed "s|^$P/||" | sort -u | paste -sd ' ' -)
  record "$name" "done" "${new:-no new entries}"
  [ "$(jq -r ".handoffs[$h].gates // false" "$CHAIN")" != true ] || check_gates "$name" "$json"
  [ "$(jq -r ".handoffs[$h].prompt_gates // false" "$CHAIN")" != true ] || check_prompt_gates "$name" "$new"
  if [ "$(jq -r ".handoffs[$h].merge_check // false" "$CHAIN")" = true ] && ! check_merge "$name"; then return 1; fi
  used=$(jq -r '(.used // []) | map(tostring) | join(" ")' <<< "$json" 2>/dev/null || true)
  [ -z "$used" ] || record "$name" "used" "$used"

  STEP_RAN=1; STEP_NEW=$(echo $STEP_NEW $new)
  # What the developer judges: entries of the hand-offs that do work, not of those that only record.
  [ "$(jq -r ".handoffs[$h].records // false" "$CHAIN")" = true ] || STEP_JUDGED=$(echo $STEP_JUDGED $new)
  [[ " $STEP_NAMES " == *" $name "* ]] || STEP_NAMES=$(echo $STEP_NAMES $name)

  # The propose-review loop: back to "loop" while the reviewer says again and rounds remain.
  back=$(jq -r ".handoffs[$h].loop // \"\"" "$CHAIN")
  if [ -n "$back" ]; then
    max=$(jq -r ".handoffs[$h].rounds // $ROUNDS" "$CHAIN")
    if [ "$(jq -r '.loop // ""' <<< "$json")" = again ] && [ "$round" -lt "$max" ]; then
      # Findings picked up go to the role the loop returns to, as the step's note.
      picked=$(jq -r '(.picked // []) | map(tostring) | join(", ")' <<< "$json")
      if [ -n "$picked" ]; then
        printf '%s\n' "The decision maker picked up these open findings, and these alone: $picked." >> "$LOG/note"
        [ ! -s "$LOG/note-read" ] || { printf '%s\n' "The developer's words with that choice:"; cat "$LOG/note-read"; } >> "$LOG/note"
      fi
      round=$((round + 1)); h=$(jq --arg n "$back" '[.handoffs[].name] | index($n)' "$CHAIN"); LOOPED=1; continue
    fi
    round=1
  fi
  h=$((h + 1))
done
if step_end end; then return 0; fi
record "end" "step complete" ""

# The submit pass. Each role that wrote entries in this step looks at them again with the whole
# step in view, sets each one's "upstream" tag, and sends each candidate to the outbox.
if [ -n "$LEG" ]; then
  for role in $(jq -r '[.handoffs[].role] | unique | .[]' "$CHAIN"); do
    h=$(jq --arg r "$role" '[.handoffs[].role] | index($r)' "$CHAIN")
    names=$(jq -r --arg r "$role" '[.handoffs[] | select(.role == $r) | .name] | join(" ")' "$CHAIN")
    mine=""; for n in $names; do
      mine="$mine $(jq -r --arg n "$n" 'select(.handoff == $n and .event == "done") | .detail' "$LOG/log.jsonl" | tr ' ' '\n' | grep '^S/data/' || true)"
    done
    mine=$(echo $mine)
    coded=$(jq -r --arg r "$role" 'select(.event == "done") | .handoff' "$LOG/log.jsonl" | grep -qx code && [ "$role" = coder ] && echo 1 || true)
    [ -n "$mine" ] || [ -n "$coded" ] || continue
    if [ "$role" = coder ]; then
      { section "$P/$AGENTS_DIR/coder/prompt.md" "program"
        echo; echo "Lower layer: $LAYER"; echo "Leg: $LEG"; echo
        echo "Program: offer each program the coder wrote in this step ($STEPS_DIR/$ID/, git log) that could help an agent of any role in another component or project. Write nothing when none could."
      } > "$TMP/submit"
      ask "$h" "$TMP/submit" "$LOG/submit-coder.reply" && record "submit" "coder offered" "see S/outbox/changes/" || record "submit" "coder failed" ""
      continue
    fi
    { section "$P/$AGENTS_DIR/$role/prompt.md" ""
      echo; echo "## Submit"; echo
      echo "You play the $role at the end of step $ID. The step so far is in $STEPS_DIR/$ID/log.jsonl, and each role's reply in $STEPS_DIR/$ID/. Your entries from this step:"
      for e in $mine; do echo "- $e"; done
      echo
      echo "For each of your entries, decide with the whole step in view whether it could help an agent of any role, in another component or project, do its own work better: to write use cases, review runs, plan, review, decide, code or review code. Set its \"upstream\" to \"candidate\" when it could, and to \"local\" when it could not, editing the file in place. Change nothing else. Reply with {\"candidates\": [\"<path>\"]}."
    } > "$TMP/submit"
    if ! ask "$h" "$TMP/submit" "$LOG/submit-$role.reply"; then record "submit" "failed" "the $role"; continue; fi
    for e in $mine; do
      [ "$(jq -r '.upstream // ""' "$P/$e" 2>/dev/null)" != candidate ] || send "$h" "$P/$e"
    done
  done
fi
echo "step: complete; the log is $LOG"
}

main "$@"; exit $?
