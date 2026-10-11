# Run reviews

One JSON file per entry, named by its `id`. Every entry also has the fields every entry has:
`id`, `by`, `status`, and, where they apply, `decided` and `made_up` (`S/specs/data.md`).

One finding: `finding`, what is wrong and what it should be; `symptom`, the evidence it rests
on, verbatim from a run record or a code review, as log lines and computed facts; `kinds`, the
kinds of fact the symptom shows; `reference`, what the symptom is judged against: a use case, a
test, a gate, a code review or an earlier run review; `severity`, from 1 (costs little) to 3
(makes the run's result unusable); `about`, `run` or the id of one part of the run's output;
`run`, the run's id, empty for a code review, or `made up`. Status: `open`, `approved`,
`rejected` or `closed`. A rejected entry stays as an example of a finding not to write.

The entries here are general samples, written in no project's terms. They are made up, and
marked so with `made_up`.
