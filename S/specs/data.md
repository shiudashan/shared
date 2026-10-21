# Data

S keeps eight types of data. Each type has its own folder under `S/data/`, with a README that
gives its format. Each entry is one JSON file, named by its `id`.

## Fields every entry has

- `id`: a short name, the file's name without `.json`.
- `by`: who wrote the entry: a role and its player, such as `run-reviewer` played by a named
  model, or a person.
- `status`: where the entry stands. The values for each type are given below.
- `decided` (when the status was set by someone other than the author): who set it, and when.
- `upstream` (optional): `local`; `candidate`, for an entry that could help an agent of any role
  in another component or project do its work better; or `accepted`, once the layer above
  accepted it. The role that writes the entry sets it at birth, and again at the step's submit
  pass (`upstream.md`).
- `reason` (optional): the developer's words when the developer answered the step that wrote the
  entry (`step.md`, "Developer mode").
- `earlier` (optional): an entry's text before the developer edited it at a gate.
- `related` (optional, on a sent entry): the ids of the entries it rests on or answers, such as
  the proposal a decision decides.
- `superseded_by` (on a retired entry): the id of the entry that replaced it. `retired` is a
  status every type may take.
- `made_up` (optional): `true` for an entry made up as an example, not taken from a run.
- `pattern` (on an entry sent to `shared`): the entry in pattern form, `{"context", "problem",
  "solution", "consequences"}`.

`S/outbox/<type>/` holds the entries this layer's roles send to the layer above, revised for
the layer above (`upstream.md`). Git keeps the outbox.

Words are recorded as given. Words someone else wrote and the developer approved are recorded with
their author in `by` and the developer in `decided`. They are never recorded as the developer's
words.

## The types

- **Use cases.** One use case of M.f: `seed`, the input a run starts from; `reference`, the
  reference answer; `rubric`, a list of weighted checks, each `{"check", "weight"}`. Status:
  `active` or `retired`.
- **Run records.** One run: `versions`, of M and of S; `settings`; `use_case`, the id of the use
  case; `trace`, every model call and tool call the run made, each with its start, end, inputs
  and outputs, nested under the call that started it, as OpenTelemetry spans; `outcome`;
  `grades`, the ids of the run grades given to the run; `cost`, with time, tokens and money.
  Status: `complete` or `abandoned`. (MLflow runs, OpenTelemetry's GenAI agent spans, SLSA
  provenance, and Anthropic's split between transcript and outcome.)
- **Run grades.** One grade of one run: `run`; `grade`, a number on a better-to-worse scale
  from 0 (worst) to 1 (best); `reason`; `grader`, recorded in `by`. Status: `given`,
  `approved` or `rejected`.
- **Run reviews.** One finding: `finding`, what is wrong and what it should be; `symptom`, the
  evidence it rests on, verbatim from a run record or a code review, as log lines and computed
  facts; `kinds`, the kinds of fact the symptom shows; `reference`, what the symptom is judged
  against: a use case, a test, a gate, a code review or an earlier run review; `severity`, from
  1 (costs little) to 3 (makes the run's result unusable); `about`, `run` or the id of one part
  of the run's output; `run`, the run's id, empty for a code review, or `made up`. Status: `open`,
  `approved`, `rejected` or `closed`. A rejected entry stays as an example of a finding not to
  write.
- **Proposals.** One change proposal: `findings`, the run reviews it answers; `gain`; `delta`,
  what the change adds, modifies or removes in the spec; `kind`; `design`; `tasks`; `check`;
  `gates`, each `{"name", "command", "dir"}` for a check a program does, or `{"name", "prompt"}`
  for one a model judges (`step.md`); `upsides` and `downsides`, each a list of `{"what", "amount", "unit"}`, kept side by side;
  `rank`, its place in the planner's order; `corrections`, the ids of the proposal reviews and
  decisions it received; `changed`, what changed since the last round. Status: `proposed`,
  `withdrawn`, `approved`, `postponed` or `done`.
- **Proposal reviews.** One review of one proposal: `proposal`; `feedback`, in words;
  `corrections`, each `{"field", "from", "to", "reason"}`; `disposition`, the recommendation:
  approve, postpone or reject; `after`, what changed in the proposal after the review. Status:
  `open` or `answered`.
- **Decisions.** One decision: `decision`, one of `approve`, `postpone`, `reject`, `release` or
  `keep`; `about`, the ids of the proposals, or the versions v and v+1; `reason`. Status:
  `final` or `reverted`.
- **Code reviews.** One review of one diff: `diff`, the commits reviewed; `change`, the id of the
  proposal it implements; `comments`, each `{"lines", "text", "rule"}`; `gates`, a verdict on each prompt gate of the
  change, each `{"name", "verdict", "reason"}` with `verdict` `pass` or `fail`; `outcome`, `accept`
  or `request changes`. Status: `open` or `closed`.

The step's gate records, `S/steps/<step id>/gates.jsonl`, are written by `S/src/gate-run.sh`, one
line per run of a command gate: `change`, `gate`, `command`, `commit`, `tree`, `clean` (true when
the work tree held nothing uncommitted outside S's own records), `exit`, `start`, `end`, and `output`, the path of the
saved output. They are records of what ran, not entries.

## Which action reads which type

A role's actions are listed in the role's spec. An x marks a type the action reads.

| Role | Action | Use cases | Run records | Run grades | Run reviews | Proposals | Proposal reviews | Decisions | Code reviews |
|---|---|---|---|---|---|---|---|---|---|
| User | run M.f after a release (step 8) | x | | | | | | | |
| User | grade a run | x | x | x | | | | | |
| User | send use cases and run grades upward | x | | x | | | | | |
| User | receive use cases and run grades from below | x | | x | | | | | |
| Developer | review proposals (step 4) | | | | x | x | x | x | |
| Developer | give feedback and corrections (step 4) | | | | | x | x | x | |
| Developer | run M.f side by side, v and v+1 (step 5) | x | | | | | | | |
| Developer | grade a trial run (step 5) | x | x | x | | | | | |
| Decision maker | approve change requests (step 4) | | | | x | x | x | x | |
| Decision maker | release v+1 or keep v (step 7) | x | x | x | | | | x | x |
| Decision maker | send decisions upward | | | | | | | x | |
| Decision maker | receive decisions from below | | | | | | | x | |
| Run reviewer | read run records (step 1) | | x | | | | | | |
| Run reviewer | read code reviews (step 1) | | | | | | | | x |
| Run reviewer | write a finding with its symptom (step 1) | | x | x | x | | | | |
| Run reviewer | name the reference a symptom is judged against (step 1) | x | | | | | | | |
| Run reviewer | grade a finding by severity (step 1) | | | x | x | | | x | |
| Run reviewer | send run reviews upward | | | | x | | | | |
| Run reviewer | receive run reviews from below | | | | x | | | | |
| Planner | write change proposals from findings (step 2) | | | | x | x | | x | |
| Planner | quantify upsides and downsides (step 2) | | | x | x | x | | | |
| Planner | order the proposals (step 2) | | | | | x | | x | |
| Planner | revise from reviews (steps 3, 4) | | | | | | x | x | |
| Planner | send proposals upward | | | | | x | | | |
| Planner | receive proposals from below | | | | | x | | | |
| Proposal reviewer | review the top proposals (step 3) | | | | x | x | x | x | |
| Proposal reviewer | give textual feedback (step 3) | | | | | | x | | |
| Proposal reviewer | give numerical corrections (step 3) | | | | | x | | x | |
| Proposal reviewer | send proposal reviews upward | | | | | | x | | |
| Proposal reviewer | receive proposal reviews from below | | | | | | x | | |
| Coder | write the change requests (step 5) | x | | | | x | | x | x |
| Coder | pass each change request's gates (step 5) | x | x | | | | | | |
| Code reviewer | review a diff (step 6) | | | | | x | | | x |
| Code reviewer | accept the code (step 6) | | | | | | | | x |
| Code reviewer | send the code back with the review (step 6) | | | | | | | | x |
| Code reviewer | send code reviews upward | | | | | | | | x |
| Code reviewer | receive code reviews from below | | | | | | | | x |
