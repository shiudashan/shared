#!/usr/bin/env bash
# Sync: brings the S of the layer above into a project or a component. The spec is
# shared/S/specs/sync.md.
#
#   S/src/sync.sh <project root>                 from shared, pinned as a submodule
#   <component>/S/src/sync.sh <component root>   from the project's S, for a folder inside a project
#
# A project copies this file from shared/S/src/sync.sh to <project>/S/src/sync.sh, customises the
# settings below and its own steps, and runs it. The first run copies shared's files into the
# project. A later run merges each change made in shared since the last run into the project's
# copy, with a three-way merge (git merge-file). The project's own changes are never overwritten.
# Conflicts are left marked in the files, and the script exits with status 1.
#
# A component (sync.md, "A component") copies the project's sync.sh unchanged. The script sees
# that its root is a folder inside a project's repository, and then reads the project's S from
# the project's git history at the project's current commit; copies no config and no survey,
# which the component inherits; leaves the project's logs and outbox behind and creates an empty
# outbox; writes the component's own CLAUDE.md on the first run; and customises the agents and
# the chain for the component.
#
# SYNC_NO_CLAUDE=1 skips the `claude -p` steps and prints what each would have done. Tests use it.
#
# The whole script is one function, so bash reads all of it before it runs. Step 1 may then
# merge a change into this very file safely.

main() {
set -euo pipefail

P=$(cd "${1:?usage: sync.sh <project root> | <component root>}" && pwd)

# --- Settings the project customises -------------------------------------------------------
TOP=$(git -C "$P" rev-parse --show-toplevel 2>/dev/null || echo "$P")
if [ "$TOP" != "$P" ]; then LAYER=component; else LAYER=project; fi
DATA_DIR="S/data"             # the layer's data folder, relative to its root
AGENTS_DIR="S/src/agents"     # the layer's agents, relative to its root
TYPES=(use-cases run-records run-grades run-reviews proposals proposal-reviews decisions code-reviews)
OUTBOX_TYPES=(use-cases run-grades run-reviews proposals proposal-reviews decisions code-reviews changes)
if [ $LAYER = component ]; then
SHARED="$TOP"                 # the layer above: the project's repository, at its current commit
C=$(basename "$P"); PROJECT=$(basename "$TOP")
GEN=$(ls -d "$P"/f[0-9]* 2>/dev/null | sed 's|.*/||' | sort -V | tail -1)  # the newest generation
# What comes from where: "<path in the project>|<path in the component>". Folders end in "/".
MAP=(
  "S/src/sync.sh|S/src/sync.sh"
  "S/src/upstream.sh|S/src/upstream.sh"
  "S/src/step.sh|S/src/step.sh"
  "S/src/gate.sh|S/src/gate.sh"
  "S/src/gate-run.sh|S/src/gate-run.sh"
  "S/src/record.sh|S/src/record.sh"
  "S/src/chain.json|S/src/chain.json"
  "S/specs/|S/specs/"
  "S/src/agents/|$AGENTS_DIR/"
)
for t in "${TYPES[@]}"; do MAP+=("S/data/$t/|$DATA_DIR/$t/"); done
JOINED=()
else
SHARED="$P/shared"            # shared, pinned as a git submodule
# What comes from where: "<path in shared>|<path in the project>". Folders end in "/".
MAP=(
  "S/src/sync.sh|S/src/sync.sh"
  "S/src/upstream.sh|S/src/upstream.sh"
  "S/src/step.sh|S/src/step.sh"
  "S/src/gate.sh|S/src/gate.sh"
  "S/src/gate-run.sh|S/src/gate-run.sh"
  "S/src/record.sh|S/src/record.sh"
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
fi
# -------------------------------------------------------------------------------------------

STAMP="$P/S/.synced-from"     # the commit of the layer above this layer was last synced to
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
is_joined() { local j; for j in ${JOINED[@]+"${JOINED[@]}"}; do [ "$j" = "$1" ] && return 0; done; return 1; }
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
  if [ $RUN = first ] && is_joined "$d" && [[ $d == *.json ]]; then   # JSON: joined by jq
    # The project's settings win; each hook list keeps the project's entries and adds shared's.
    jq -s '.[0] as $s | .[1] as $p | ($s * $p) | .hooks = ((($s.hooks // {}) | keys) + (($p.hooks // {}) | keys) | unique
      | map({key: ., value: ((($p.hooks // {})[.] // []) + (($s.hooks // {})[.] // []) | unique)}) | from_entries)
      | if .hooks == {} then del(.hooks) else . end' "$n" "$dp" > "$TMP/joined" && cp "$TMP/joined" "$dp" && MERGED+=("$d (joined)")
    return 0
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
chmod +x "$P/.claude/hooks/"*.py "$P/S/src/upstream.sh" "$P/S/src/step.sh" "$P/S/src/gate.sh" "$P/S/src/gate-run.sh" "$P/S/src/record.sh" 2>/dev/null || true
if [ $LAYER = component ]; then
  for t in "${OUTBOX_TYPES[@]}"; do
    [ -e "$P/S/outbox/$t/.gitkeep" ] || { mkdir -p "$P/S/outbox/$t"; : > "$P/S/outbox/$t/.gitkeep"; ADDED+=("S/outbox/$t/"); }
  done
fi

# 2.2 Config, for a component: on the first run, the component's own CLAUDE.md.
if [ $LAYER = component ] && [ $RUN = first ] && [ ! -e "$P/CLAUDE.md" ]; then
  ask "write CLAUDE.md" "Write CLAUDE.md in this folder, $C, a component of the project $PROJECT. \
Claude Code also loads the project's CLAUDE.md (in the parent folder) in every session here, so \
state only $C's own rules, and repeat nothing the parent states. In S's terms, $PROJECT is the \
project M, and $C is one of its components, holding its own plan (M.p, spec/) and prototype (M.f, \
its generations f0/, f1/ and so on). Draw the rules from README.md, spec/ and the project's spec: \
what $C is, where its plan and generations sit, that S/ develops $C, and its release rules, in \
the project's own form. Keep it short. Do not read obsolete/ or any archived copy." \
  && ADDED+=("CLAUDE.md") || true
fi

# 2.4 Programs: each role's agent, and the chain, are customised for the layer when they arrive:
#     on the first run, or on a later run that adds them.
new_here() { [ $RUN = first ] && return 0; local a; for a in ${ADDED[@]+"${ADDED[@]}"}; do [ "$a" = "$1" ] && return 0; done; return 1; }
if [ $LAYER = component ]; then
  for r in "$P/$AGENTS_DIR"/*/; do
    [ -d "$r" ] || continue
    role=$(basename "$r")
    new_here "$AGENTS_DIR/$role/prompt.md" || continue
    ask "customise $AGENTS_DIR/$role" "The agent in $AGENTS_DIR/$role/ was customised for \
$PROJECT, the project. Customise it further for $C, the component of $PROJECT in this folder. \
Read its role spec in S/specs/$role.md, CLAUDE.md here and in the parent folder, README.md, \
spec/, and the current generation $GEN/. Edit prompt.md and settings.json in place so the agent \
knows, as far as the role needs, $C as a whole: what $C is (in S's terms, $PROJECT is the project \
M, and $C is one of its components, holding its own plan M.p in spec/ and its own prototype M.f \
in its generations), how its generations are laid out, where a generation keeps its code and \
tests, and the release rules. Add \"generation\": \"$GEN\" to settings.json, keep every key name \
settings.json already has, write a generation's files as <generation>/<file>, and have prompt.md \
refer to the current generation through that setting, so a new generation changes the setting \
only. Do not read obsolete/. Keep the role's actions and data, and its Send and Receive duties, \
as the spec gives them; $C's outbox is S/outbox/<type>/, and $PROJECT receives from it." || true
  done
  new_here "S/src/chain.json" && ask "customise S/src/chain.json" "Customise S/src/chain.json, the chain of S's step for $C, a \
component of the project $PROJECT (S/specs/step.md, \"Triggering and chaining\"). Set \"layer\" \
to two or three sentences a stranger needs: what $C is, and what its own terms mean. Set \"leg\" \
to \"project\", the leg to the layer above. Set \"run_command\" to the command, run from this \
folder, that runs $C's current generation $GEN on one use case. Leave the hand-offs and every \
other setting as they are." || true
else
  for r in "$P/$AGENTS_DIR"/*/; do
    [ -d "$r" ] || continue
    role=$(basename "$r")
    new_here "$AGENTS_DIR/$role/prompt.md" || continue
    ask "customise $AGENTS_DIR/$role" "Customise the agent in $AGENTS_DIR/$role/ for this \
project. Read its role spec in S/specs/$role.md, the project's CLAUDE.md, and the project's own \
specs and code. Edit prompt.md and settings.json in place so the agent knows, as far as the role \
needs, the project as a whole: what the project is, how the project lays out its prototypes and \
their generations, its release rules, and its languages and review rules. The rules every \
role shares are in $AGENTS_DIR/global.md; do not repeat them. Name no \
single prototype or generation, and point to no folder inside one: the project's own sync adds \
what is specific to a generation. Do not read obsolete/ or any archived copy. Keep the role's \
actions and data as the spec gives them." || true
  done
  new_here "S/src/chain.json" && ask "customise S/src/chain.json" "Customise S/src/chain.json, the chain of S's step for this \
project (S/specs/step.md, \"Triggering and chaining\"). Set \"layer\" to two or three sentences \
a stranger needs: what the project is, and what its own terms mean. Set \"leg\" to \"shared\", the \
leg to the layer above. Set \"run_command\" to the command that runs the project's program on one \
use case, if the project has one, or leave it empty. Leave the hand-offs as they are." || true
fi
# Recording is a program's job (S/specs/step.md, "Triggering and chaining"). A layer whose users'
# runs hold more than files gets its own recorder once, here, rather than a model at every step.
new_here "S/src/record.sh" && ask "set up recording" "S/src/record.sh records seeds and runs \
with no model (S/specs/step.md, \"Triggering and chaining\"). In S/src/chain.json, set \"seeds\" \
to the folder, from this folder, where users' seeds for this layer's program are kept (each item one \
seed), \"user_runs\" to the folder where users' own runs are kept (each subfolder one run), or \
leave either empty when there is none, and write {seed} in \"run_command\" where the seed goes. \
When a user's run holds more than S/src/record.sh records, such as the words the user gave in each \
round, write S/src/record-runs.sh, a program that first runs S/src/record.sh . runs and then adds \
those words to each run record word for word (S/specs/data.md, run records), and set the \
\"program\" of the \"runs\" hand-off to it. It must call no model. Leave everything else as it is." || true

for f in "$P/$AGENTS_DIR"/*/settings.json "$P/S/src/chain.json"; do
  [ ! -e "$f" ] || jq -e . "$f" >/dev/null 2>&1 || KEPT+=("${f#"$P/"} (not valid JSON; fix it)")
done
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
