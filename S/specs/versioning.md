# Versioning

Each generation n of a project has versions n.0, n.1, n.2, and so on.

- **n.0** is the generation as it starts from the one before.
- **Each later version is one change.** It is one commit holding the change's spec, code and
  tests, tagged `<generation>.<k>` in git. So a past version can be rebuilt from its tag, and a
  change can be taken into another line on its own, by its commit.
- **`<generation>/VERSION`** holds the current version. A run prints it at start and records it
  in its run record.
- **`<generation>/CHANGELOG.md`** has one entry per version, newest last. Each entry names the
  commit of every change it lists.

An entry keeps two kinds of change apart:
- **In project:** the project's prototype, its specification, and the project's own S.
- **Cross project:** what serves every project. That is the S in `shared`, and the datasets
  that serve every project.

