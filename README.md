# shared

Shared is a agent on agents. It has two parts:
- a development system S
- a survey pipeline that (1) delivers implicit feature improvement requests to S 
(2) clusters the input requests to train and test sampes 
(3) execute the modification to improve S.

## The properties for the automatic software develop agent S

With so many software development agents, why do we develop a new one S?
We think that the software development agents on the markets are optimized 
for the "feature request - pull request - test and release" flow. They interpret
every interaction with the user to that narrow form. Thus, there is a lot
of frustration because the user needs to be very speficif in terms of
what to tell the coder. The user must adjust what to instruct based on
business reality, based on what it thinks the coder still remembers, and
so on. 

S is an agent built on other agents, such as aider. Its job is to be an
intelligent buffer between the user and the underlying agents. Putting it
in other words, much of S's work is to COUNTER the bothersome tendency 
of the underlying agents on behalf of the user. For instace:

- Commercial coding agents assume that the user knows what the user wants. So 
they assume a concrete, non-changing, mission statement. However, the user should 
adapt the mission from what surprise gained during the building-a-softwar process. 
Thus the goal statement, or the mission statement, will evlove, and a the software 
building app should anticipate and accommodate such change. 

- Commercial coding agents assume that the users give good instructions. However,
a user can chat with analogy, sarcasm, "I can't believe", "do not", or just 
flat out only partially correct statement. The system we build must be sympathetic
of the fact that humans are busy and are not perfect. Humans do not wish to 
micro-manage a coder. So our system is like a great butler, able to see through 
the intent of the user from the user's remarks, and manage the agents to reflect
the underlying intent not the surface words. And when there is doubt, our system
often use even-more-plain language than the one the user uses, to lead to a  
constructive framing that the user SHOULD HAVE given. 

- Commercial coding agents tend to have very short time horizon. Without a long time horizon,
is is hard to prioritize **getting out of local optimal**. In other words, they often cannot 
accept getting worse first and stop there, knowing that some further steps can get things better
than staying in the vicinity of the original. 
An example is that an older version of code could be slow, but improving slowness may 
temporarily regress other performance at first. Our system must find a good way to frame 
the tasks so as to guide the underlying agents through the "get worse" part. 

- Commercial coding agents are very single, narrow, and **binary** minded. For **binary** 
minded, for instance, commercial agents can regard a code to either be correct or not correct, 
and can keep perfecting a rewrite until it's 100% correct. So our system must break 
down steps to a work in several installments, so the agents can deliver partially
correct, but more correct, works, so that the other part of the software
can already benefit. There are many good reasons to suspend a development in mid way;
for instance, the rest of the codes may be in a poor state, and it makes more sense to
freeze this front here to move to improve others first.

- Commercial coding agents are very single minded, with one objective and a binary 
score. But building a software is about compromises. One cannot make all attributes perfect. 
The objective is always a multi-dimensional vector whose axial values are to be maximized
but may values can move opposite each other. For instance, one of the axis is the inverse 
line count; fewer lines mean a larger inverse line count and that's preferred, but fewer 
lines can mean fewer features. Thus our system must weigh global balances to guide the 
underlying agents. When explaining the global consequences confuse the underlying agents, 
our system must devise a way to guide.

- Commercial coding agents solve in a recursive editing way. What happened is always
in the context buffer, even if what happened is wrong. However, it is often desirable 
to return to a past state to "do over", with perhaps an improved instruction to make
repeating the same mistake less likely. Thus our system must find a way to return the
coder to an original state, then give the coder an instruction with the benefit of 
the hindsight.


## Learning through observation

The system should develop itself 

## What the repository holds

### The agent S

- `S/` is the development system. S develops, reviews, and improves a project, one step at a time.
  - `S/specs/` holds the specs: (the spec subsumes the mantras and habits engineering work is judged by), how to
    build from a specification, versioning, the steps of S (`step.md`), the roles in a step, the
    data, the concept of sync.
  - `survey/` holds surveys of industrial and research practice.
  - `S/src/` holds the programs,
  - `S/config/` holds the configuration for Claude Code: `CLAUDE.md` with the general working
    rules, and `.claude/` with the settings, hooks and skills.
  - `S/outbox/` is how S sends training-worthy data from projects to a shared place where these data
    will allow S to evolve. 
  - `S/data/` holds data to send to S's global learning agent

### The learner L

- `L/` is a system that reads the upstream data, make training and testing datasets, 
modify S by reasoning over the training set, and accept modifications only if 
the improvement proves working on the test set.
- `L/` is not yet built.

### How a project syncs from shared

1. Pin shared as a submodule: `git submodule add https://github.com/shiudashan/shared shared`.
2. Copy `shared/S/src/sync.sh` to `S/src/sync.sh`, and customise it for the project.
3. Run `S/src/sync.sh .`. It copies the surveys, specs, config, data formats and agents into the
   project, joins `CLAUDE.md` and `.claude/settings.json` with the project's own, and
   customises each agent for the project. Review, customise and commit the result.

To take later changes, move the pin (`git submodule update --remote shared`) and run
`S/src/sync.sh .` again. It merges shared's changes into the project's copies with a three-way merge,
and leaves the project's own changes in place. The spec is `S/specs/sync.md`.

A component of a project gets its own S the same way, from the project's S (`S/specs/sync.md`,
"A component"). To run a step of S on a layer: `S/src/step.sh .` (`S/specs/step.md`).
