# Code reviewer

The code reviewer reviews the diff before release, at step 6 of the step (`step.md`). The code
reviewer either accepts the code or sends the code back to the coder with the review. Either way
the review is written down, and the run reviewer reads it at step 1.

## Actions

Each action names the data types it reads (`data.md`) and what it writes.

- **Review a diff (step 6).** Reads proposals and code reviews, together with the diff, the
  delta to M.p and the program's verdicts on the change's command gates. Writes a code review.
- **Judge the prompt gates (step 6).** Reads the change's proposal, the logs and the source.
  Writes a verdict, pass or fail with its reason, on each prompt gate into the code review.
- **Accept the code (step 6).** Reads code reviews. Writes the outcome "accept" into the code
  review.
- **Send code reviews upward.** Reads code reviews at the code reviewer's layer. Writes each
  revised entry into `S/outbox/code-reviews/`.
- **Receive code reviews from below.** Reads each received entry alone. Accepts or drops the
  entry, with a reason.

## Upstream

The code reviewer carries code reviews upward, as `upstream.md` states for every role. The code
reviewer sends a review when a comment applies a rule that code in another program can break.
When the code reviewer revises a review, the code reviewer keeps each comment's text, the
comment's rule, the cited lines and the outcome word for word, and replaces each file and
function name by what the code does. When the code reviewer receives a review, the code reviewer
accepts the review when the code reviewer reaches the same outcome from the comments and the
cited lines alone, and when the rule serves programs beyond the program the review came from.

## Reviews

A review is accept or request changes, with comments, each tied to lines of the diff. Each
comment names the rule it applies: the change's spec, a mantra or habit (`mantras.md`,
`habits.md`), or an example the developer gave. A ready-made code-review agent, configured with
the specs and the developer's examples, may play the role (survey-ready-made-reviewers). (Google
code review; GitHub's required review, approve or request changes.)

The code reviewer learns from the developer's data on the path given in `run-reviewer.md`.

## Sources

`survey/survey-ready-made-reviewers.md`, `survey/survey-simulated-reviewer.md` and
`survey/survey-improvement-step.md` in the repository `shared`.
