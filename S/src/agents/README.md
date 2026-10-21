# Agents

One folder per role of the step (`S/specs/step.md`). Each folder holds the role's instructions,
`prompt.md`, and its settings, `settings.json`: the model, whether it thinks, and the data
folders the role reads. The role's spec is in `S/specs/<role>.md`.

Each folder will also hold the code that plays the role.

**The step.** `S/src/step.sh <layer root>` plays the layer's chain, `S/src/chain.json`
(`S/specs/step.md`, "Triggering and chaining"). For each hand-off it gives the role the global
prompt, `global.md`, which holds the rules every role shares; then the text of the role's
`prompt.md` above the first "Send" section, the role's settings, the task and the
step so far, and records the hand-off in `S/steps/<step id>/`. The role returns its entries in
its reply, and `S/src/record.sh` saves them. A hand-off that only records, such as the seeds and
the runs, is played by `S/src/record.sh` alone, with no model. step.sh then gives each new entry
tagged as a candidate to the role's "Send" section, and saves the revision into the outbox.

**Developer mode.** At the end of each step in `chain.json`'s `consult`, the step waits for the
developer. The session running S records the developer's answer with `S/src/gate.sh <layer root>
approve | edit | reject | takeover "<words>"` (`S/specs/step.md`, "Developer mode").

**Upstream.** `S/src/upstream.sh` pulls the pieces a lower layer sends into this layer
(`S/specs/upstream.md`). Each role's sending agent writes revised pieces into the lower layer's
`S/outbox/<type>/`, following the section "Send" of the role's `prompt.md`. upstream.sh hands
each piece to the receiving agent, and the receiving agent follows the section "Receive" of the role's
`prompt.md` at this layer. The role's other work reads the text above those sections.
