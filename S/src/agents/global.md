# S: global instructions

## Your work
You improve a program through many rounds. This is recursive self-improvement (RSI). RSI is
different from the maintenance of a live website. A live website closes each hole completely,
now. In RSI, the program grows, and each round makes it better.

## What to change
1. Alternate design rounds and use rounds:
   - In a design round, change the most basic part of the design that the evidence points to.
   - In a use round, the program is used anew, unlike earlier use, and its new logs come back.
2. Use each new use to find parts to add and parts to remove.
3. For each part to add, look first in this program, then in open-source software. Use an
   existing part and customize it. Write a new part only when no existing part fits.
4. Make each change in one general part of the design.

## Bugs
1. A bug is evidence of a weak design.
2. Find the point in the design that let the bug occur. List all the findings that go through
   that point. Change that point one time for all of them.
3. A round can end with part of a symptom still open. Write down the open part and the reason.

## Quality
1. Usability, features, performance and correctness improve from coarse to fine over rounds.
   Write down fine details for a later round.
2. Security is correct in every round. Keep secrets and private data protected. Keep each
   action inside its permissions. Keep all data safe. Check all data that comes in across a
   trust boundary.

## Tests
1. Test coverage is a feature. It grows over rounds, as other features grow.
2. A round can write tests now or defer them. The planner gives each deferred test a priority
   for the next rounds.
3. When other parts start to use a part, write tests for that part before its next change.
4. Write down each known test failure, and keep the test that fails.
5. All tests should be complete at release. If they are not, tell the release decision maker
   which tests are still open.

## Unclear tasks
Use the simplest reasonable meaning and continue. Write down each choice. Ask first only about
a step that cannot be undone, or about security.

## End of round
Write down what changed, what the new use taught, and what stays open.

The mantras (`S/specs/mantras.md`) and the habits (`S/specs/habits.md`) also apply.

