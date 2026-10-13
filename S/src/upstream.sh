#!/usr/bin/env bash
# Upstream: pulls the pieces a lower layer sends into an upper layer. The spec is
# shared/S/specs/upstream.md.
#
#   S/src/upstream.sh <upper layer root> <lower layer root>
#
# For each type and each piece in <lower>/S/outbox/<type>/, the receiving agent of the role that
# owns the type judges the piece from the piece alone, with the section "Receive" of
# <upper>/S/src/agents/<role>/prompt.md, and accepts or drops the piece. upstream.sh copies each
# accepted piece into <upper>/S/data/<type>/, and prints a report. A piece the upper layer
# already holds unchanged is skipped; a changed one is judged again; a retired one retires the
# upper layer's copy. upstream.sh writes nothing to the lower layer.
#
# Clustering happens here, where the pieces of every lower layer meet. For each piece, a cheap
# lexical score picks the few held entries of the same type most like it, and the receiving
# agent sees them: it may judge the piece a duplicate of one, which is dropped, or a replacement
# of one, which retires the held entry. (Staged deduplication: a cheap score finds candidate
# pairs, and the expensive judgement runs only on them, as in NeMo Curator and SemDeDup.)
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

ACCEPTED=() DROPPED=() SKIPPED=() FAILED=() SENT=() RETIRED=()
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

receive_section() {  # receive_section <prompt.md> <words>: the "## Receive" section about <words>
  awk -v w="$2" '
    /^## / { on = ($0 ~ /^## Receive/ && index($0, w) > 0) }
    on' "$1"
}

nearest() {  # nearest <piece> <dir>: the held entries of <dir> most like <piece>, best first
  python3 -I - "$1" "$2" "${NEAREST:-3}" <<'PY'
import sys, os, re, math, collections
piece, d, k = sys.argv[1], sys.argv[2], int(sys.argv[3])
words = lambda t: collections.Counter(re.findall(r"\w{3,}", t.lower()))
a = words(open(piece).read())
def cos(b):
    n = sum(a[w] * b[w] for w in a)
    return n / (math.sqrt(sum(v * v for v in a.values())) * math.sqrt(sum(v * v for v in b.values())) or 1)
held = [os.path.join(d, f) for f in os.listdir(d) if f.endswith(".json")] if os.path.isdir(d) else []
same = os.path.basename(piece)
scored = sorted(((cos(words(open(f).read())), f) for f in held if os.path.basename(f) != same), reverse=True)
for score, f in scored[:k]:
    if score >= 0.2: print(f)
PY
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
    local near; near=$(nearest "$piece" "$U/$DATA_DIR/$type")
    if [ -n "$near" ]; then
      echo; echo "Held entries:"
      for f in $near; do echo; head -c 3000 "$f"; done
    fi
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
    if [ -e "$dest" ] && cmp -s "$piece" "$dest"; then SKIPPED+=("$type/$id: already in $DATA_DIR/$type/"); continue; fi
    if [ "$(jq -r '.status // ""' "$piece")" = retired ]; then
      if [ -e "$dest" ]; then
        jq --arg by "$(jq -r '.superseded_by // ""' "$piece")" '.status = "retired" | .superseded_by = $by' "$dest" > "$TMP/ret" && cp "$TMP/ret" "$dest"
        RETIRED+=("$type/$id")
        up="$U/$OUTBOX_DIR/$type/$id.json"   # retirement chains upward too
        [ ! -e "$up" ] || { jq '.status = "retired"' "$up" > "$TMP/ret" && cp "$TMP/ret" "$up"; }
      fi
      continue
    fi
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
      duplicate) DROPPED+=("$type/$id ($role): a duplicate of $(jq -r '.of // ""' <<< "$verdict"): $reason") ;;
      supersedes)
        of=$(jq -r '.of // ""' <<< "$verdict"); old="$U/$DATA_DIR/$type/$of.json"
        mkdir -p "$(dirname "$dest")"; cp "$piece" "$dest"; ACCEPTED+=("$type/$id ($role), superseding $of: $reason")
        if [ -n "$of" ] && [ -e "$old" ]; then
          jq --arg by "$id" '.status = "retired" | .superseded_by = $by' "$old" > "$TMP/ret" && cp "$TMP/ret" "$old"
          RETIRED+=("$type/$of, by $id")
          up="$U/$OUTBOX_DIR/$type/$of.json"
          [ ! -e "$up" ] || { jq --arg by "$id" '.status = "retired" | .superseded_by = $by' "$up" > "$TMP/ret" && cp "$TMP/ret" "$up"; }
        fi
        if [ -n "$UP_LEG" ] && [ "$(jq -r '.general // false' <<< "$verdict")" = true ]; then
          send_on "$role" "$words" "$dest" && SENT+=("$type/$id ($role)") || FAILED+=("$type/$id: the $role did not send it on")
        fi ;;
      *)      FAILED+=("$type/$id: the $role gave no decision: $verdict") ;;
    esac
  done
done

say() { local t=$1; shift; [ $# -gt 0 ] || return 0; echo "$t:"; printf '  %s\n' "$@"; }
say "accepted, copied into $DATA_DIR/" ${ACCEPTED[@]+"${ACCEPTED[@]}"}
say "dropped" ${DROPPED[@]+"${DROPPED[@]}"}
say "skipped" ${SKIPPED[@]+"${SKIPPED[@]}"}
say "sent on, into $OUTBOX_DIR/" ${SENT[@]+"${SENT[@]}"}
say "retired, superseded" ${RETIRED[@]+"${RETIRED[@]}"}
say "failed" ${FAILED[@]+"${FAILED[@]}"}
echo "upstream: ${#ACCEPTED[@]} accepted, ${#DROPPED[@]} dropped, ${#SKIPPED[@]} skipped, ${#FAILED[@]} failed."
[ ${#FAILED[@]} -eq 0 ]
}

main "$@"; exit $?
