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
layer's context. The sending agent picks each piece that serves beyond the lower layer, revises
the piece for the layer above, and writes the revised piece into the lower layer's outbox:
`<lower>/S/outbox/<type>/<id>.json`. Git keeps the outbox. A piece stays in the outbox after
upstream.sh reads the piece.

The role tags each entry at birth, `"upstream": "local"` or `"upstream": "candidate"` (`data.md`).
`step.sh` gives the sending agent its first opportunity: as soon as the role writes a candidate,
`step.sh` hands the entry to the same role's section "Send" (`step.md`).

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
piece alone, and does the piece serve beyond the layer the piece came from. The receiving agent
accepts the piece when both answers are yes, and drops the piece otherwise, with a reason. The
receiving agent never revises a piece. The role's `prompt.md` at the upper layer holds the
receiving agent's instructions, in the section "Receive".

## upstream.sh

The upper layer runs the upper layer's copy of `S/src/upstream.sh` to pull from the layer below:
`S/src/upstream.sh <upper root> <lower root>`. A person runs upstream.sh by hand; a schedule
runs upstream.sh later. For each type and each piece in `<lower>/S/outbox/<type>/`, upstream.sh
takes four steps.

1. upstream.sh skips the piece when `<upper>/S/data/<type>/` already holds a piece with the
   piece's id.
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
