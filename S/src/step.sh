#!/usr/bin/env bash
# Step: plays one step of S on a layer, hand-off by hand-off. The spec is shared/S/specs/step.md,
# "Triggering and chaining".
#
#   S/src/step.sh <layer root>                       starts a new step
#   S/src/step.sh <layer root> --from <hand-off>     resumes the latest step at that hand-off
#
# The chain is <layer>/S/src/chain.json. For each hand-off, step.sh gives the hand-off's role its
# instructions (<layer>/S/src/agents/<role>/prompt.md, up to its first "## Send"), its settings,
# the task, and the step so far, in one `claude -p` call in the layer root. The role writes its
# entries into <layer>/S/data/<type>/. step.sh records the hand-off in the step's log,
# <layer>/S/steps/<step id>/, and has the role's sending agent revise each new entry tagged
# "upstream": "candidate" into <layer>/S/outbox/<type>/. step.sh stops at a hand-off that waits
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
section() {  # section <prompt.md> <send words>: the role's instructions, or its "## Send" section
  if [ -z "$2" ]; then awk '/^## Send/ {exit} {print}' "$1"
  else awk -v w="$2" '/^## / { on = ($0 ~ /^## Send/ && index($0, w) > 0) } on' "$1"; fi
}
entries() {  # entries <types...>: every entry file of those types, one path per line
  local t; for t in "$@"; do ls -1 "$P/$DATA_DIR/$t"/*.json 2>/dev/null || true; done | sort
}
ask() {  # ask <hand-off index> <message file> <reply file>
  local h=$1 role model flags
  role=$(jq -r ".handoffs[$h].role" "$CHAIN")
  model=$(jq -r '.model // "no preference"' "$P/$AGENTS_DIR/$role/settings.json" 2>/dev/null || echo "no preference")
  flags=(); while IFS= read -r f; do flags+=("$f"); done < <(jq -r "(.handoffs[$h].claude_flags // .claude_flags // [])[]" "$CHAIN")
  [ "$model" = "no preference" ] || flags+=(--model "$model")
  if [ "${STEP_NO_CLAUDE:-}" = 1 ]; then echo '{"skipped": "STEP_NO_CLAUDE=1"}' > "$3"; return 0; fi
  (cd "$P" && S_RUN_KIND="${RUN_KIND:-}" claude -p "${flags[@]}" < "$2") > "$3"
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

h=$START; round=1
while [ "$h" -lt "$N" ]; do
  name=$(jq -r ".handoffs[$h].name" "$CHAIN")
  role=$(jq -r ".handoffs[$h].role" "$CHAIN")
  start=$(jq -r ".handoffs[$h].start // \"auto\"" "$CHAIN")
  run=$(jq -r ".handoffs[$h].run // \"\"" "$CHAIN")
  writes=(); while IFS= read -r w; do writes+=("$w"); done < <(jq -r ".handoffs[$h].writes[]" "$CHAIN")

  # A hand-off whose needed types gained no entry earlier in this step has nothing to work on.
  needs=$(jq -r ".handoffs[$h].needs // [] | join(\" \")" "$CHAIN")
  if [ -n "$needs" ]; then
    got=""; for t in $needs; do grep -q "\"detail\":\"[^\"]*S/data/$t/" "$LOG/log.jsonl" 2>/dev/null && got=1; done
    if [ -z "$got" ]; then record "$name" "skipped" "no new $needs in this step"; h=$((h + 1)); continue; fi
  fi

  # A hand-off that waits for a person stops the step, unless the person resumed right here.
  if [ "$start" = person ] && [ "$name" != "$FROM" ]; then
    record "$name" "waits for a person" "the $role"
    echo "step: a person reads the step so far in $LOG, then either runs"
    echo "  S/src/step.sh $P --from $name        to have the $role act, or"
    echo "  plays the $role, writes the entries, and runs --from the next hand-off."
    return 0
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
      echo "Write each entry you produce as one JSON file, $DATA_DIR/<type>/<entry id>.json, for the types: ${writes[*]}. Follow the format in $DATA_DIR/<type>/README.md and S/specs/data.md. Set \"by\" to \"$role\" with who plays it, and \"upstream\" to \"local\", or to \"candidate\" when the entry may serve the layer above."
    fi
    [ -z "$RUN_KIND" ] || echo "The run command: $RUN_COMMAND. S_RUN_KIND=$RUN_KIND is set, so M.f logs as a $RUN_KIND run."
    echo "End your reply with the action's JSON, as your instructions give it."
  } > "$TMP/message"

  record "$name" "starts" "the $role${RUN_KIND:+, $RUN_KIND runs}"
  reply="$LOG/$(printf '%02d' "$h")-$name-$round.reply"
  if ! ask "$h" "$TMP/message" "$reply"; then record "$name" "failed" "claude -p failed; resume with --from $name"; return 1; fi
  json=$(perl -0777 -ne 'print $1 if /(\{.*\})\s*$/s' "$reply" | jq -c . 2>/dev/null || true)
  [ -n "$json" ] || json='{}'

  entries ${writes[@]+"${writes[@]}"} > "$TMP/after"
  new=$(comm -13 "$TMP/before" "$TMP/after" | sed "s|^$P/||" | paste -sd ' ' -)
  record "$name" "done" "${new:-no new entries}"

  # The sending agent's first opportunity: each new candidate goes to the outbox.
  if [ -n "$LEG" ]; then
    for e in $(comm -13 "$TMP/before" "$TMP/after"); do
      [ "$(jq -r '.upstream // ""' "$e" 2>/dev/null)" != candidate ] || send "$h" "$e"
    done
  fi

  # The propose-review loop: back to "loop" while the reviewer says again and rounds remain.
  back=$(jq -r ".handoffs[$h].loop // \"\"" "$CHAIN")
  if [ -n "$back" ]; then
    if [ "$(jq -r '.loop // ""' <<< "$json")" = again ] && [ "$round" -lt "$ROUNDS" ]; then
      round=$((round + 1)); h=$(jq --arg n "$back" '[.handoffs[].name] | index($n)' "$CHAIN"); continue
    fi
    round=1
  fi
  h=$((h + 1))
done
record "end" "step complete" ""
echo "step: complete; the log is $LOG"
}

main "$@"; exit $?
