# Habits

Gentle reminders for writing and reviewing specs and code. Following them is not mandatory;
departing from one is worth a sentence of reason.

## Making runs visible
1. When a run starts, show every parameter that changes its behaviour, once, in the terminal.
2. Log every call: what it was, when it ran, and how its time and tokens split, cached input and
   thinking included. Keep a full call-by-call profile of runs that matter.
3. Check the environment at start: the services a run needs answer, and vendored code holds
   exactly its patches. Stop with a plain message if not.

## Checks and limits
4. Check from where the thing is used: a page from the machine a person reads it on, a
   permission by an action that tries to cross it. A check that passes because nothing happened
   is not a pass.
5. Every limit has an enforcer in the program. A limit that only logs, or only asks the model to
   stop, is a wish.

## Specs and prompts
6. Change the spec first, then the code. Review the spec before code is built from it. A
   behaviour that lives only in code is lost at the next rebuild.
7. Keep content and metadata apart, in specs and in what the system itself writes and shows: what
   a thing is, separately from notes about it (what comes later, what was set aside, how the run
   is going, where an idea came from). Reasoning that explains the content is content.
8. One rule per decision, across all prompts. Two rules that pull against each other, or a
   question that carries its asker's own pick, cost thinking and give nothing.

## Shaping work
9. Ask for review before doing the work a decision governs, not after.
10. Keep the critical path short. Work nobody waits on runs in the background at lower priority.
11. Don't redo work whose inputs haven't changed.
12. Let the program do mechanical work and models do judgment.
13. Give an agent the inputs it needs in its message, and only those.
14. Choose each role's settings by its eval: its model, how much it thinks, and its step budget.

## Iterating
15. Keep a generation's cycle short: try it, close it with a lessons file, start the next.
16. Keep set-aside items in one circle-back file, each saying what was given up and when to
    return to it.
17. When a new generation replaces an old one, check behaviour by behaviour that what the old one
    did is kept or deliberately dropped.

## Data
18. Keep every word a user or the developer gives, with what it was about, as data, written as
    it is given. Never record words as someone's that they did not give.

## Reproducibility
19. Keep every version rebuildable and every run traceable to the version that made it. Pin what
    the program depends on and check the pins at start. Give each change its own version: one
    commit holding its spec, code and tests, tagged, with a changelog entry. Record in each run
    the version and the settings it ran with.

