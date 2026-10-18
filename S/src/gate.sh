#!/usr/bin/env bash
# Gate: the developer's answer at the end of a step that waits for the developer. The spec is
# shared/S/specs/step.md, "Developer mode". Claude Code, running S with the developer, records the
# developer's words with it; the developer does not type it.
#
#   S/src/gate.sh <layer root> approve ["words"]   the step's entries pass on; the words, if any,
#                                                  go to the next role as the developer's direction
#   S/src/gate.sh <layer root> edit ["words"]      correct each entry in $EDITOR, then pass them on
#   S/src/gate.sh <layer root> reject "words"      the step is done again from its first working
#                                                  hand-off, with the developer's words in hand
#   S/src/gate.sh <layer root> takeover ["words"]  the step's entries are set aside; the developer's
#                                                  own entries are written, then the step goes on
#
# The developer's words are kept verbatim: in the entries ("status", "decided", "reason", and
# "earlier" for an edit) and in the step's log. Then the step goes on.
#
# The whole script is one function, so bash reads all of it before it runs.

main() {
set -euo pipefail
P=$(cd "${1:?usage: gate.sh <layer root> approve|edit|reject|takeover [words]}" && pwd)
WHAT=${2:?usage: gate.sh <layer root> approve|edit|reject|takeover [words]}
WORDS=${3:-}
STEPS_DIR="S/steps"
ID=$(ls -1 "$P/$STEPS_DIR" 2>/dev/null | tail -1)
LOG="$P/$STEPS_DIR/$ID"
[ -n "$ID" ] && [ -f "$LOG/gate" ] || { echo "gate: no step waits for the developer in $P" >&2; exit 2; }
STEP=$(jq -r .step "$LOG/gate"); NEXT=$(jq -r '.next // "end"' "$LOG/gate"); REDO=$(jq -r '.redo // ""' "$LOG/gate")
DECIDED="the developer, $(date +%F)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

mark() {  # mark <entry> <status>: the developer's decision, kept in the entry
  jq --arg s "$2" --arg d "$DECIDED" --arg r "$WORDS" '.status = $s | .decided = $d | (if $r != "" then .reason = $r else . end)' "$P/$1" > "$TMP/e" && cp "$TMP/e" "$P/$1"
}
log() {
  jq -nc --arg h "step $STEP" --arg e "developer: $1" --arg d "$WORDS" --arg t "$(date +%FT%T)" '{at: $t, handoff: $h, event: $e, detail: $d}' >> "$LOG/log.jsonl"
  echo "  step $STEP: developer: $1${WORDS:+ ($WORDS)}"
}
entries() { jq -r '.entries[]' "$LOG/gate"; }

case "$WHAT" in
  approve)
    for e in $(entries); do mark "$e" approved; done
    [ -z "$WORDS" ] || printf '%s\n' "$WORDS" > "$LOG/note"
    log approve ;;
  edit)
    for e in $(entries); do
      cp "$P/$e" "$TMP/before"; ${EDITOR:-vi} "$P/$e"
      jq -e . "$P/$e" >/dev/null || { cp "$TMP/before" "$P/$e"; echo "gate: $e is not valid JSON; kept as it was" >&2; continue; }
      if ! cmp -s "$TMP/before" "$P/$e"; then
        jq --slurpfile b "$TMP/before" '.earlier = ($b[0] | del(.earlier))' "$P/$e" > "$TMP/e" && cp "$TMP/e" "$P/$e"
      fi
      mark "$e" approved
    done
    log edit ;;
  reject)
    [ -n "$WORDS" ] || { echo "gate: give the developer's words, so the step can be done again with them" >&2; exit 2; }
    for e in $(entries); do mark "$e" rejected; done
    printf '%s\n' "$WORDS" > "$LOG/note"
    log reject
    rm -f "$LOG/gate"
    exec bash "$P/S/src/step.sh" "$P" --from "${REDO:-$NEXT}" ;;
  takeover)
    for e in $(entries); do mark "$e" rejected; done
    log takeover
    rm -f "$LOG/gate"
    echo "gate: write the developer's entries into S/data/<type>/, with \"by\" the developer, then run"
    echo "  S/src/step.sh $P --from $NEXT"
    exit 0 ;;
  *) echo "gate: approve, edit, reject or takeover" >&2; exit 2 ;;
esac
rm -f "$LOG/gate"
exec bash "$P/S/src/step.sh" "$P" --from "$NEXT"
}

main "$@"; exit $?
