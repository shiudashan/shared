#!/usr/bin/env bash
# Sync: brings shared's S into a project. The spec is shared/S/specs/sync.md.
#
#   S/src/sync.sh <project root>
#
# A project copies this file from shared/S/src/sync.sh to <project>/S/src/sync.sh, customises the
# settings below and its own steps, and runs it. The first run copies shared's files into the
# project. A later run merges each change made in shared since the last run into the project's
# copy, with a three-way merge (git merge-file). The project's own changes are never overwritten.
# Conflicts are left marked in the files, and the script exits with status 1.
#
# A component of a project (spec: sync.md, "A component") copies the project's sync.sh to
# <component>/S/src/sync.sh and customises it: SHARED becomes the project's root, read from the
# project's git history; the config lines and the survey leave MAP; the data lines name each type,
# so the project's logs stay behind; the outbox is created empty; the first run writes the
# component's own CLAUDE.md; and the customisation describes the component.
#
# SYNC_NO_CLAUDE=1 skips the `claude -p` steps and prints what each would have done. Tests use it.
#
# The whole script is one function, so bash reads all of it before it runs. Step 1 may then
# merge a change into this very file safely.

main() {
set -euo pipefail

P=$(cd "${1:?usage: sync.sh <project root>}" && pwd)

# --- Settings the project customises -------------------------------------------------------
SHARED="$P/shared"            # shared, pinned as a git submodule
DATA_DIR="S/data"             # the project's data folder, relative to the project root
AGENTS_DIR="S/src/agents"     # the project's agents, relative to the project root
# What comes from where: "<path in shared>|<path in the project>". Folders end in "/".
MAP=(
  "S/src/sync.sh|S/src/sync.sh"
  "S/src/upstream.sh|S/src/upstream.sh"
  "S/src/step.sh|S/src/step.sh"
  "S/src/chain.json|S/src/chain.json"
  "survey/|S/survey/"
  "S/specs/|S/specs/"
  "S/config/CLAUDE.md|CLAUDE.md"
  "S/config/.claude/settings.json|.claude/settings.json"
  "S/config/.claude/hooks/|.claude/hooks/"
  "S/config/.claude/skills/|.claude/skills/"
  "S/data/|$DATA_DIR/"
  "S/outbox/|S/outbox/"
  "S/src/agents/|$AGENTS_DIR/"
)
# Files joined with the project's own on the first run, rather than copied.
JOINED=("CLAUDE.md" ".claude/settings.json")
# -------------------------------------------------------------------------------------------

STAMP="$P/S/.synced-from"     # the commit of shared this project was last synced to
[ -d "$SHARED/.git" ] || [ -f "$SHARED/.git" ] || { echo "sync: no shared at $SHARED; pin it first (step 0)" >&2; exit 2; }
NEW=$(git -C "$SHARED" rev-parse HEAD)
BASE=""
[ -f "$STAMP" ] && BASE=$(cat "$STAMP")
if [ -z "$BASE" ]; then RUN=first; else RUN=later; fi
echo "sync: $RUN run, shared ${BASE:0:12}${BASE:+ -> }${NEW:0:12}, project $P"

ADDED=() UPDATED=() MERGED=() CONFLICTS=() RESOLVED=() REMOVED=() KEPT=() SKIPPED=()
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

ask() {  # ask <what> <prompt>: a judgement step, done by claude -p in the project root
  if [ "${SYNC_NO_CLAUDE:-}" = 1 ]; then SKIPPED+=("$1"); return 1; fi
  (cd "$P" && claude -p --permission-mode acceptEdits "$2") && return 0
  SKIPPED+=("$1 (claude -p failed)"); return 1
}
is_joined() { local j; for j in "${JOINED[@]}"; do [ "$j" = "$1" ] && return 0; done; return 1; }
files_at() {  # files_at <commit> <path>: the files under a path of shared at a commit
  [ -n "$1" ] && git -C "$SHARED" ls-tree -r --name-only "$1" -- "$2" || true
}
show_at() {  # show_at <commit> <file> <out>: a file of shared at a commit, empty if absent
  if [ -n "$1" ] && git -C "$SHARED" cat-file -e "$1:$2" 2>/dev/null; then
    git -C "$SHARED" show "$1:$2" > "$3"; else : > "$3"; fi
}

sync_file() {  # sync_file <file in shared> <file in the project>
  local s=$1 d=$2 dp="$P/$2" b="$TMP/base" n="$TMP/new" inb inn
  show_at "$BASE" "$s" "$b"; show_at "$NEW" "$s" "$n"
  [ -n "$BASE" ] && git -C "$SHARED" cat-file -e "$BASE:$s" 2>/dev/null && inb=1 || inb=0
  git -C "$SHARED" cat-file -e "$NEW:$s" 2>/dev/null && inn=1 || inn=0
  if [ $inb = 1 ] && [ $inn = 1 ] && cmp -s "$b" "$n"; then return 0; fi   # unchanged in shared
  if [ $inn = 0 ]; then                                                     # removed in shared
    if [ -f "$dp" ] && cmp -s "$dp" "$b"; then rm "$dp"; REMOVED+=("$d")
    elif [ -f "$dp" ]; then KEPT+=("$d (removed in shared, changed here)"); fi
    return 0
  fi
  if [ ! -e "$dp" ]; then
    if [ $inb = 1 ]; then KEPT+=("$d (changed in shared, deleted here; left deleted)"); return 0; fi
    mkdir -p "$(dirname "$dp")"; cp "$n" "$dp"; ADDED+=("$d"); return 0
  fi
  cmp -s "$dp" "$n" && return 0                                             # already the same
  if [ $inb = 0 ] && [[ $d == "$DATA_DIR/"* ]] && [ -e "$P/S/outbox/${d#"$DATA_DIR/"}" ]; then  # sent up, accepted above
    jq '.upstream = "accepted"' "$dp" > "$TMP/acc" 2>/dev/null && cp "$TMP/acc" "$dp"
    KEPT+=("$d (accepted by the layer above; this layer's version kept)"); return 0
  fi
  if [ $RUN = first ] && is_joined "$d"; then
    ask "join $d" "Join shared's general version of $d, below, with this project's own $d. \
For CLAUDE.md: put the general rules above the project's own sections, keep every project \
section, and drop general rules the project already states. For settings.json: merge the two \
JSON objects, keeping every project setting and adding shared's hooks and settings. Edit $d in \
place. Shared's version:
$(cat "$n")" && MERGED+=("$d (joined)")
    return 0
  fi
  if cmp -s "$dp" "$b"; then cp "$n" "$dp"; UPDATED+=("$d"); return 0; fi  # not changed here
  if [[ $d == *.json ]] && jq -e . "$dp" "$b" "$n" >/dev/null 2>&1; then  # JSON: one layout for all three
    local f; for f in "$dp" "$b" "$n"; do jq --sort-keys . "$f" > "$TMP/norm" && cp "$TMP/norm" "$f"; done
  fi
  if git merge-file -L project -L "shared ${BASE:0:12}" -L "shared ${NEW:0:12}" "$dp" "$b" "$n"; then
    MERGED+=("$d")
  elif ask "resolve $d" "$d has merge conflicts between this project's version and shared's new \
version, marked with <<<<<<< project, ======= and >>>>>>> shared. Resolve each conflict in place \
so the result keeps both intents: the project's customisation and shared's change. Remove every \
marker. Change nothing outside the conflicts." && ! grep -q '^<<<<<<< project' "$dp"; then
    RESOLVED+=("$d")
  else
    CONFLICTS+=("$d")
  fi
}

sync_entry() {  # sync_entry <path in shared> <path in the project>
  local s=$1 d=$2 f
  if [[ $s != */ ]]; then sync_file "$s" "$d"; return; fi
  { files_at "$BASE" "$s"; files_at "$NEW" "$s"; } | sort -u > "$TMP/list"
  while IFS= read -r f; do sync_file "$f" "$d${f#"$s"}"; done < "$TMP/list"
}

# 1. The project's sync workflow. A later run first merges shared's changes to sync.sh into
#    this file, and runs again from the merged file.
if [ $RUN = later ] && [ -z "${SYNC_REEXEC:-}" ]; then
  before=$(cksum < "$P/S/src/sync.sh")
  sync_file "S/src/sync.sh" "S/src/sync.sh"
  if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo "sync: S/src/sync.sh has conflicts with shared's new version; resolve them and run again" >&2; exit 1
  fi
  if [ "$before" != "$(cksum < "$P/S/src/sync.sh")" ]; then
    echo "sync: S/src/sync.sh took shared's changes; running the merged script"
    SYNC_REEXEC=1 exec bash "$P/S/src/sync.sh" "$P"
  fi
fi

# 2.1 to 2.4. Documents, config, data and programs, in the order of MAP.
for m in "${MAP[@]}"; do
  s=${m%%|*}; d=${m#*|}
  [ "$d" = "S/src/sync.sh" ] && continue        # handled in step 1
  sync_entry "$s" "$d"
done
chmod +x "$P/.claude/hooks/"*.py "$P/S/src/upstream.sh" "$P/S/src/step.sh" 2>/dev/null || true

# 2.4 Programs: on the first run, each role's agent is customised for the project.
if [ $RUN = first ]; then
  for r in "$P/$AGENTS_DIR"/*/; do
    [ -d "$r" ] || continue
    role=$(basename "$r")
    ask "customise $AGENTS_DIR/$role" "Customise the agent in $AGENTS_DIR/$role/ for this \
project. Read its role spec in S/specs/$role.md, the project's CLAUDE.md, and the project's own \
specs and code. Edit prompt.md and settings.json in place so the agent knows, as far as the role \
needs, the project as a whole: what the project is, how the project lays out its prototypes and \
their generations, its release rules, its standards, and its languages and review rules. Name no \
single prototype or generation, and point to no folder inside one: the project's own sync adds \
what is specific to a generation. Do not read obsolete/ or any archived copy. Keep the role's \
actions and data as the spec gives them." || true
  done
  ask "customise S/src/chain.json" "Customise S/src/chain.json, the chain of S's step for this \
project (S/specs/step.md, \"Triggering and chaining\"). Set \"layer\" to two or three sentences \
a stranger needs: what the project is, and what its own terms mean. Set \"leg\" to \"shared\", the \
leg to the layer above. Set \"run_command\" to the command that runs the project's program on one \
use case, if the project has one, or leave it empty. Leave the hand-offs as they are." || true
fi

echo "$NEW" > "$STAMP"

# 2.5 Report.
say() { local t=$1; shift; [ $# -gt 0 ] || return 0; echo "$t:"; printf '  %s\n' "$@"; }
say "added" ${ADDED[@]+"${ADDED[@]}"}
say "updated" ${UPDATED[@]+"${UPDATED[@]}"}
say "merged" ${MERGED[@]+"${MERGED[@]}"}
say "removed" ${REMOVED[@]+"${REMOVED[@]}"}
say "kept" ${KEPT[@]+"${KEPT[@]}"}
say "conflicts resolved by claude -p; review them" ${RESOLVED[@]+"${RESOLVED[@]}"}
say "conflicts, left marked" ${CONFLICTS[@]+"${CONFLICTS[@]}"}
say "claude -p steps skipped" ${SKIPPED[@]+"${SKIPPED[@]}"}
echo "sync: review, customise and commit the changes, with the moved pin of shared."
[ ${#CONFLICTS[@]} -eq 0 ]
}

main "$@"; exit $?
