# Reference feedback

The person's feedback on runs, each with the evidence it rests on. The run reviewer and the
simulated user draw from these entries to give feedback on a new run as the person would, when
the new run shows what an entry's log showed.

Entries live in every layer. Each layer's `feedback/` holds the entries of that layer; an entry
that proves useful beyond its layer moves up through upstream. The entries in `shared` are
written in no project's terms. They test whether the reviewers carry a fault across projects.

## The entry format

One JSON file per entry:

- `id`: a short name, the file's name without `.json`.
- `run`: the run the feedback was given on, or `"made up"`.
- `question` or `monitor` (optional): the question the feedback answered, or the monitor that
  raised the symptom.
- `kinds`: the kinds of fact the entry rests on, named as the project's program names the facts
  it computes from a run, such as `priorities` or `overlap`. A run's facts are compared with an
  entry by these kinds.
- `log`: the symptom: the evidence the feedback rests on, verbatim from the run, as log lines
  and as facts the program computed.
- `feedback`: the feedback itself, short and plain: what is wrong, with its numbers, and what it
  should be.
- `reason` (optional): why, in the words of whoever gave the feedback, when the feedback does
  not already say it.
- `about`: `"run"` for how the run went as a whole, or the id of one part of the run's output.
- `by`: who wrote the words.
- `status`: `"approved"` or `"rejected"`.
- `approved` or `rejected`: who decided the entry, and when.
- `note`: the person's own words given with the decision, verbatim. Absent when none was given.
- `made_up`: `true` for an entry made up at the person's request, not taken from a run. It is
  set in a kind of program of its own, with that program's log lines.

A rejected entry is feedback the person turned down. It stays as an example of feedback not to
give, and grounds no feedback.

## Adding feedback

New feedback is a new entry. The reviewers' prompts do not change.

Words the person wrote are recorded with `by` the person. Words someone else wrote and the
person approved are recorded with their author in `by` and the person in `approved`. They are
never recorded as the person's words.
