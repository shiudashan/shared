# Agents

One folder per role of the step (`S/specs/step.md`). Each folder holds the role's instructions,
`prompt.md`, and its settings, `settings.json`: the model, whether it thinks, and the data
folders the role reads. The role's spec is in `S/specs/<role>.md`.

Each folder will also hold the code that plays the role.

**Upstream.** `S/src/upstream.sh` pulls the pieces a lower layer sends into this layer
(`S/specs/upstream.md`). Each role's sending agent writes revised pieces into the lower layer's
`S/outbox/<type>/`, following the section "Send" of the role's `prompt.md`. upstream.sh hands
each piece to the receiving agent, and the receiving agent follows the section "Receive" of the role's
`prompt.md` at this layer. The role's other work reads the text above those sections.
