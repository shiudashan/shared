# Upstream

Upstream carries a role's work from a layer to the layer above it: from a component to its
project (leg 3), and from a project to `shared` (leg 4). Sync (`sync.md`) carries work down;
upstream carries work up. One pair of programs serves every upper and lower pair of layers:
`S/src/sync.sh` down, `S/src/upstream.sh` up.

## Roles and types

Each role sends the type the role writes, and receives the same type at the layer above:

- the user sends use cases and run grades;
- the decision maker sends decisions;
- the run reviewer sends run reviews;
- the planner sends proposals;
- the proposal reviewer sends proposal reviews;
- the code reviewer sends code reviews;
- the coder sends changes: a reusable program, with the program's tests and spec.

## The sending agent

The sending agent is the role's agent at the lower layer. The sending agent holds the lower
layer's context. The sending agent picks each piece that could help an agent of any role, in
another component or project, do its own work better. The agent helped need not play the
sending role: a run reviewer's finding may teach another project's user which use cases to
write. The sending agent revises
the piece for the layer above, and writes the revised piece into the lower layer's outbox:
`<lower>/S/outbox/<type>/<id>.json`. Git keeps the outbox. A piece stays in the outbox after
upstream.sh reads the piece.

The role tags each entry at birth, `"upstream": "local"` or `"upstream": "candidate"` (`data.md`).
The value of an entry often shows only later in the step, as when a review corrects a proposal.
So the step ends with a submit pass (`step.md`): each role that wrote entries in the step tags
them again with the whole step in view, and `step.sh` hands each candidate to the role's section
"Send". The coder offers, in the same pass, each program it wrote that could serve elsewhere.

A sent piece stands as it is at the end of the step, with the corrections of later reviews and
decisions folded in, and names in `related` the entries it rests on or answers. A piece sent
again goes under the same id.

The sending agent revises each piece into the smallest form that still shows the piece's point,
plus the context a stranger needs. The sending agent keeps the evidence and the verdict word for
word: log lines, diff hunks, the grade and the grade's reason, numbers with their units. The
sending agent adds only what removes an ambiguity: the meaning of each lower-layer id and term,
one sentence on the environment, and the reference in words. The sending agent drops each part
whose removal leaves the verdict unchanged.

On leg 4 the sending agent also replaces the project's terms by their meaning, and fills
`pattern` (`data.md`). Where the evidence cannot shed the project's domain, the sending agent
writes a made-up minimal instance that keeps the verdict, and sets `made_up` to true.

## The receiving agent

The receiving agent is the same role's agent at the upper layer. The receiving agent lacks the
lower layer's context, so the receiving agent judges each piece as received, from the piece
alone. The receiving agent asks two questions: can the role reach the piece's verdict from the
piece alone, and could the piece help an agent of any role beyond the layer the piece came
from. The receiving agent
accepts the piece when both answers are yes, and drops the piece otherwise, with a reason. The
receiving agent never revises a piece.

Clustering happens at the receiver, where the pieces of every lower layer meet. The receiving
agent sees the few held entries most like the piece. When the piece adds nothing to one of them,
the receiving agent judges it a duplicate, and the piece is dropped. When the piece teaches the
same lesson better, or corrects a held entry, the receiving agent judges that it supersedes the
entry: the piece is accepted, and the held entry is retired, `"status": "retired"` with
`superseded_by`. (Staged deduplication: a cheap score finds candidate pairs, and the expensive
judgement runs only on them; NeMo Curator, SemDeDup.) The role's `prompt.md` at the upper layer holds the
receiving agent's instructions, in the section "Receive".

## upstream.sh

The upper layer runs the upper layer's copy of `S/src/upstream.sh` to pull from the layer below:
`S/src/upstream.sh <upper root> <lower root>`. A person runs upstream.sh by hand; a schedule
runs upstream.sh later. For each type and each piece in `<lower>/S/outbox/<type>/`, upstream.sh
takes four steps.

1. upstream.sh skips the piece when `<upper>/S/data/<type>/` already holds it unchanged. A
   changed piece is judged again, and replaces the held one when accepted. A retired piece
   retires the held copy, and the copy in the upper layer's outbox, without a judgement.
   Otherwise upstream.sh picks, by a cheap lexical score, the few held entries of the same type
   most like the piece, and passes them to the receiving agent with the piece.
2. upstream.sh hands the piece to the receiving agent, with one `claude -p` call. The receiving
   agent accepts or drops the piece, with a reason.
3. upstream.sh copies an accepted piece into `<upper>/S/data/<type>/`.
4. upstream.sh prints a report: each accepted, dropped and skipped piece, with the reason.

upstream.sh writes nothing back to the lower layer.

On leg 4 the project's `shared`, the git submodule at `<project>/shared`, runs upstream.sh
against the project. A git merge then carries the accepted pieces from the project's `shared`
to the global `shared`. That merge lies outside upstream.sh.

## Sources

`survey/survey-upstreaming.md` (judgement on the piece's own merits: Linux, Debian,
InnerSource; a person as final decider: Fedora). `survey/survey-example-context.md` (keep, add,
drop: minimal reproducible examples, decontextualisation; pattern form).
