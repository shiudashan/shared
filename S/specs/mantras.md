# Mantras

The principles underlying how we do engineering work. Whether we plan, spec, survey, code, 
run experiment, debug, communicate, review, debate, use the mantras as criteria as guiding
principles. 

This document gives the mantras. A mantra might be broad and inclusive, so for some
we also give examples. 

Each project shall keeps its own examples of each mantra, in the words of whoever gave them, 
as we encourage a certain degree of customization of mantras for a project. 

## Unify and simplify

One general path, grown to fit each new case. It pays most once we are sure enough of what we
want that several things we had to describe separately can be described together, in one
coherent and shorter way. Before that, separate descriptions are the honest state.

- When a new case behaves like the existing ones, widen the general path until the case is
  ordinary, rather than adding a branch beside it. When a case really is different, a branch is
  the right shape; keep it.
- The question for every branch: is the difference real, or did the branch appear because the
  general path was too narrow to absorb the case? Only the second kind goes.
- A branch of the second kind is cheap once and expensive forever: it behaves differently, is
  tested separately, and must be remembered. Widening the path is expensive once, and every case
  gains from it.
- Widening often means rewriting the general path, and the rewrite looks risky. The test is the
  next new case: if it needs no new branch, the rewrite was right.
- If widening is too hard right now, add the branch as a marked debt: say in the code why the
  path could not take the case, and record it with the postponed work. When a second case needs
  a branch for the same reason, widen the path then; two cases show its shape.
- Simplify removes code that does not need to exist, even when it does no harm. A guard against
  a failure that can really happen is needed, and stays.
- Unneeded branches often appear where a graded signal could do the job but was cut into yes/no
  cases. Let the score drive the one path.
- Words are paths too. Where a field already has a well-built term for a thing, use it rather
  than coining our own; invent a word only when none fits.

## Bugs indicate poor architecture

Instead of doing the locally right thing to quiet a bug, it is more rewarding to improve the
architecture, even if the bug is not fully closed for a while.

When a bug surfaces a more general issue, address the general issue, whether that makes the
bug's symptom better or worse for now.

Existing code is often an earlier, intentionally simpler implementation. When it runs into an
issue that was to be expected, rewrite it with a better, more thoughtful design, using the
hindsight. Everything improves, with no trade-off except perhaps more code, which is accepted.
This is not a design question for the developer.

## Move hard-coded parameters into configuration

After hard-coding parameters to get a function working, consider moving them into
configuration objects.

## Fail early, fail loud.

When the behavior of a program deviates from what is expected, produce loud errors, in log,
console log, and even terminate the program if necessary.

A hallmark of AI-driven behavior, expressed in a pseudo code, is

if (sympton that can predict the primary path will fail) { use this secondary path }

Such pattern also invites the use of hard coded values for the sympton prediction,
see above.

This biggest sin of this kind of behavior is that usually these come from AI rewrites
against unit test failures. Director, or other agents, are complete unaware of this
type of terrible local patches. 

Instead, when error happens, let the Director and other agents know. These announced 
errors feed into "unify and simply", and avoid "hard coded parameters".
