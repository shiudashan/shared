# Building from a specification

A project is built from specifications: one for the system, and one for each component.

- **Specs come first.** A change in behaviour is made in its spec first, then in the code. If
  the code must behave in a way its spec does not allow, change the spec in the same commit and
  say so.
- **Read a spec generously.** If its words allow a behaviour, the behaviour is allowed. A general
  sentence names a set of acceptable designs; pick one. Read its words at the strength they are
  written: "usually" is not "always", and "can" is not "must".
- **Where it names a standard technique,** use it the way its usual libraries give it. Do not
  invent extra machinery around it.
- **Where it is silent, decide.** Different builds from one spec are expected to differ. Record
  each choice the spec left open in the project's `DECISIONS.md`, one line each: what was chosen
  and why, in a few words.
- **When how other software behaves matters, read its source.** Docs and source often disagree,
  and the source is what runs.
- **A limit of one build is not a hole in the spec.**
- **A rebuild reads the previous generation.** A new generation is built from its spec, and its
  builders read all of the previous generation's code as hindsight.

