#!/usr/bin/env bash
# Gate: the person's decision at a hand-off that waits for the person. The spec is
# shared/S/specs/step.md, "Triggering and chaining".
#
#   S/src/gate.sh <layer root> approve [reason]    pass the role's entries on
#   S/src/gate.sh <layer root> edit [reason]       correct each entry in $EDITOR, then pass them on
#   S/src/gate.sh <layer root> reject <reason>     send the entries back: the role writes them again
#   S/src/gate.sh <layer root> takeover [reason]   set the entries aside; the person writes the role's
#
# The decision is kept in the entries themselves (data.md): "status" approved or rejected,
# "decided" the person with the date, and "reason" in the person's own words. An edited entry
# keeps its earlier text in "earlier". The step's log records the gate. Then the step goes on.
#
# The whole script is one function, so bash reads all of it before it runs.

main() {
set -euo pipefail
P=$(cd "${1:?usage: gate.sh <layer root> approve|edit|reject|takeover [reason]}" && pwd)
WHAT=${2:?usage: gate.sh <layer root> approve|edit|reject|takeover [reason]}
REASON=${3:-}
CHAIN="$P/S/src/chain.json" STEPS_DIR="S/steps"
ID=$(ls -1 "$P/$STEPS_DIR" 2>/dev/null | tail -1)
LOG="$P/$STEPS_DIR/$ID"
[ -n "$ID" ] && [ -f "$LOG/gate" ] || { echo "gate: no step waits for the person in $P" >&2; exit 2; }
NAME=$(jq -r .handoff "$LOG/gate"); ROLE=$(jq -r .role "$LOG/gate")
NEXT=$(jq -r --arg n "$NAME" '[.handoffs[].name] as $a | ($a | index($n)) as $i | $a[$i + 1] // "end"' "$CHAIN")
DECIDED="the person, $(date +%F)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

mark() {  # mark <entry> <status>: the person's decision, kept in the entry
  jq --arg s "$2" --arg d "$DECIDED" --arg r "$REASON" '.status = $s | .decided = $d | (if $r != "" then .reason = $r else . end)' "$P/$1" > "$TMP/e" && cp "$TMP/e" "$P/$1"
}
log() {
  jq -nc --arg h "$NAME" --arg e "gate: $1" --arg d "$REASON" --arg t "$(date +%FT%T)" '{at: $t, handoff: $h, event: $e, detail: $d}' >> "$LOG/log.jsonl"
  echo "  $NAME: gate: $1${REASON:+ ($REASON)}"
}
entries() { jq -r '.entries[]' "$LOG/gate"; }

case "$WHAT" in
  approve)
    for e in $(entries); do mark "$e" approved; done
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
    [ -n "$REASON" ] || { echo "gate: say why, so the $ROLE can write it again" >&2; exit 2; }
    for e in $(entries); do mark "$e" rejected; done
    echo "$REASON" > "$LOG/gate-note"
    log reject
    rm -f "$LOG/gate"
    exec bash "$P/S/src/step.sh" "$P" --from "$NAME" ;;
  takeover)
    for e in $(entries); do mark "$e" rejected; done
    log takeover
    rm -f "$LOG/gate"
    echo "gate: write the $ROLE's entries into S/data/<type>/, with \"by\" the person, then run"
    echo "  S/src/step.sh $P --from $NEXT"
    exit 0 ;;
  *) echo "gate: approve, edit, reject or takeover" >&2; exit 2 ;;
esac
rm -f "$LOG/gate"
exec bash "$P/S/src/step.sh" "$P" --from "$NEXT"
}

main "$@"; exit $?
