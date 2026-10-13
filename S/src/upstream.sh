#!/usr/bin/env bash
# Upstream: pulls the pieces a lower layer sends into an upper layer. The spec is
# shared/S/specs/upstream.md.
#
#   S/src/upstream.sh <upper layer root> <lower layer root>
#
# For each type and each piece in <lower>/S/outbox/<type>/, the receiving agent of the role that
# owns the type judges the piece from the piece alone, with the section "Receive" of
# <upper>/S/src/agents/<role>/prompt.md, and accepts or drops the piece. upstream.sh copies each
# accepted piece into <upper>/S/data/<type>/, skips a piece the upper layer already holds, and
# prints a report. upstream.sh writes nothing to the lower layer.
#
# Acceptance chains upward: when the upper layer has a layer above it (a "leg" in its
# S/src/chain.json) and the receiving agent judged the piece general, the same role at the upper
# layer sends the piece on, with the section "Send" of its prompt.md, into <upper>/S/outbox/<type>/.
#
# UPSTREAM_NO_CLAUDE=1 skips the `claude -p` steps and judges nothing. Tests use it.
#
# The whole script is one function, so bash reads all of it before it runs.

main() {
set -euo pipefail

U=$(cd "${1:?usage: upstream.sh <upper root> <lower root>}" && pwd)
L=$(cd "${2:?usage: upstream.sh <upper root> <lower root>}" && pwd)

# --- Settings the layer customises ---------------------------------------------------------
DATA_DIR="S/data"             # the upper layer's data folder
OUTBOX_DIR="S/outbox"         # the lower layer's outbox, and the upper layer's
AGENTS_DIR="S/src/agents"     # the upper layer's agents
# Which role receives which type: "<type>|<role>|<the words in the role's Receive heading>".
OWNERS=(
  "use-cases|user|use case"
  "run-grades|user|run grade"
  "decisions|decision-maker|decision"
  "run-reviews|run-reviewer|run review"
  "proposals|planner|proposal"
  "proposal-reviews|proposal-reviewer|proposal review"
  "code-reviews|code-reviewer|code review"
  "changes|coder|change"
)
# -------------------------------------------------------------------------------------------

command -v jq >/dev/null || { echo "upstream: needs jq" >&2; exit 2; }
# The upper layer's own leg to the layer above it, and so the leg the pieces come up.
UP_LEG=$(jq -r '.leg // ""' "$U/S/src/chain.json" 2>/dev/null || echo "")
UP_LAYER=$(jq -r '.layer // ""' "$U/S/src/chain.json" 2>/dev/null || echo "")
if [ -n "$UP_LEG" ]; then LEG=project; else LEG=shared; fi
echo "upstream: lower $L -> upper $U"

ACCEPTED=() DROPPED=() SKIPPED=() FAILED=() SENT=()
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

receive_section() {  # receive_section <prompt.md> <words>: the "## Receive" section about <words>
  awk -v w="$2" '
    /^## / { on = ($0 ~ /^## Receive/ && index($0, w) > 0) }
    on' "$1"
}

judge() {  # judge <type> <role> <words> <piece>: prints the receiving agent's JSON verdict
  local type=$1 role=$2 words=$3 piece=$4 prompt="$U/$AGENTS_DIR/$2/prompt.md" model section
  [ -f "$prompt" ] || { echo "no prompt at $prompt" >&2; return 1; }
  section=$(receive_section "$prompt" "$words")
  [ -n "$section" ] || { echo "no Receive section about \"$words\" in $prompt" >&2; return 1; }
  model=$(jq -r '.model // "no preference"' "$U/$AGENTS_DIR/$role/settings.json" 2>/dev/null || echo "no preference")
  {
    echo "$section"
    echo
    echo "Layer: $(basename "$U")"
    echo "Leg: $LEG"
    echo
    echo "Entry:"
    cat "$piece"
  } > "$TMP/message"
  local args=(-p --tools "")
  [ "$model" = "no preference" ] || args+=(--model "$model")
  (cd "$TMP" && claude "${args[@]}" < "$TMP/message") > "$TMP/reply" || return 1
  perl -0777 -ne 'print $1 if /(\{.*\})/s' "$TMP/reply" | jq -c . 2>/dev/null
}

send_on() {  # send_on <role> <words> <entry>: the role at the upper layer sends the entry on
  local section
  section=$(awk -v w="$2" '/^## / { on = ($0 ~ /^## Send/ && index($0, w) > 0) } on' "$U/$AGENTS_DIR/$1/prompt.md")
  [ -n "$section" ] || return 1
  printf '%s\n\nLower layer: %s\nLeg: %s\n\nEntry:\n%s\n' "$section" "$UP_LAYER" "$UP_LEG" "$(cat "$3")" > "$TMP/send"
  (cd "$U" && claude -p --permission-mode acceptEdits < "$TMP/send") > "$TMP/send-reply"
}

for o in "${OWNERS[@]}"; do
  IFS='|' read -r type role words <<< "$o"
  dir="$L/$OUTBOX_DIR/$type"
  [ -d "$dir" ] || continue
  for piece in "$dir"/*.json; do
    [ -e "$piece" ] || continue
    id=$(jq -r '.id // empty' "$piece" 2>/dev/null || true)
    [ -n "$id" ] || id=$(basename "$piece" .json)
    dest="$U/$DATA_DIR/$type/$id.json"
    if [ -e "$dest" ]; then SKIPPED+=("$type/$id: already in $DATA_DIR/$type/"); continue; fi
    if [ "${UPSTREAM_NO_CLAUDE:-}" = 1 ]; then SKIPPED+=("$type/$id: not judged (UPSTREAM_NO_CLAUDE=1)"); continue; fi
    if ! verdict=$(judge "$type" "$role" "$words" "$piece") || [ -z "$verdict" ]; then
      FAILED+=("$type/$id: the $role gave no verdict"); continue
    fi
    decision=$(jq -r '.decision // empty' <<< "$verdict")
    reason=$(jq -r '.reason // empty' <<< "$verdict")
    case "$decision" in
      accept) mkdir -p "$(dirname "$dest")"; cp "$piece" "$dest"; ACCEPTED+=("$type/$id ($role): $reason")
        if [ -n "$UP_LEG" ] && [ "$(jq -r '.general // false' <<< "$verdict")" = true ]; then
          send_on "$role" "$words" "$dest" && SENT+=("$type/$id ($role)") || FAILED+=("$type/$id: the $role did not send it on")
        fi ;;
      drop)   DROPPED+=("$type/$id ($role): $reason") ;;
      *)      FAILED+=("$type/$id: the $role gave no decision: $verdict") ;;
    esac
  done
done

say() { local t=$1; shift; [ $# -gt 0 ] || return 0; echo "$t:"; printf '  %s\n' "$@"; }
say "accepted, copied into $DATA_DIR/" ${ACCEPTED[@]+"${ACCEPTED[@]}"}
say "dropped" ${DROPPED[@]+"${DROPPED[@]}"}
say "skipped" ${SKIPPED[@]+"${SKIPPED[@]}"}
say "sent on, into $OUTBOX_DIR/" ${SENT[@]+"${SENT[@]}"}
say "failed" ${FAILED[@]+"${FAILED[@]}"}
echo "upstream: ${#ACCEPTED[@]} accepted, ${#DROPPED[@]} dropped, ${#SKIPPED[@]} skipped, ${#FAILED[@]} failed."
[ ${#FAILED[@]} -eq 0 ]
}

main "$@"; exit $?
