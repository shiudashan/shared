# Layered templates: established practice for the plan's layers, build down and build up

Most of the plan's sections 3 to 6 have an established equivalent. The layering itself is
standard. So is "same file names in every layer, concatenated in order", which is exactly how
Claude Code loads CLAUDE.md files. The lock file, the first scaffolding and the later updates of a
customised project map onto Copier. Build up maps onto pull requests to the shared repository,
in the inner-source style. Two details are ours with no established equivalent: the folder name
`S/`, and moving a reference entry up by first rewriting it in general terms and checking that it
still catches the fault.

One place in the plan conflicts with established practice. A sibling clone plus a lock file does
not pin anything by itself. Claude Code's import reads `~/shared/S/CLAUDE.md` at whatever commit
the clone has checked out, not the commit in `shared.lock`. Established multi-repo tools solve
this with a manifest and an update command that checks out the pinned commit (west, repo), or
with a git submodule.

## The plan restated with established equivalents

Each line gives the plan's detail, then what replaces it. "Ours" means no established equivalent
was found.

### Section 3: the layers

- **Three layers, broad to specific.** Established. Claude Code loads managed, user, project and
  local CLAUDE.md files, broad first. Git has system, global, local and worktree configuration.
  Kustomize calls the broad layer a *base* and each specific one an *overlay*. Adopt "base" and
  "overlay" when describing the relation. Keep "pan-project, in-project, in-iteration" as the
  names of our three levels.
- **The same file names in every layer.** Established. CLAUDE.md, AGENTS.md, `.editorconfig` and
  `.claude/rules/` all use one name at every level. Keep.
- **A folder `S/` in each layer.** Ours. The nearest convention is a tool-owned folder at the
  root, such as `.claude/`, `.cursor/` or `.github/`. Keep `S/`.
- **`shared` as a sibling clone at `~/shared`.** Established as a multi-repo *workspace*: Zephyr's
  west and Google's repo keep sibling clones under one root and record each clone's revision in a
  manifest. Adopt the manifest's discipline: build down checks out the pinned commit, not just
  records it. A git submodule is the other established form. It nests `shared` inside each
  project and pins it in the project's own commit.
- **`shared.lock`.** Established, under two names depending on the role. As a template pin it is
  Copier's `.copier-answers.yml`, which records the template source and `_commit`. As a
  workspace pin it is a west manifest entry with a `revision`. Adopt `.copier-answers.yml` if
  `shared` becomes a Copier template (see section 5 below). Otherwise keep `shared.lock`.
- **Merge by concatenation, in the order shared, project, iteration.** Established. This is
  Claude Code's rule for CLAUDE.md: files are concatenated, not overridden, and the more specific
  file is read last. Keep.
- **Data folders as the union of the layers' entries.** Established. `.claude/rules/` and skills
  folders are unions. When two layers hold the same name, the established rule is that the
  nearest layer wins (git config, Helm values, EditorConfig, AGENTS.md). Claude Code skills are
  the exception: personal beats project. Adopt "nearest layer wins" for a repeated id.
- **Code is not concatenated; the project adds extensions.** Established. This is a library plus
  plugins, not a layer merge. Claude Code plugins, Nx plugins and Yeoman generators all work
  this way. Keep.
- **`effective/`, built at iteration start.** Established as *rendered output*: `kustomize build`
  and `helm template` produce the merged files from base and overlays. Practice splits on whether
  to keep it. Most tools render in memory and offer a command to print the result
  (`git config --list --show-origin`, `tsc --showConfig`, ESLint `--print-config`). The
  *rendered manifests pattern* commits the rendered result so that each diff shows what actually
  ran. Keep `effective/`. Its `SOURCES` file is the `--show-origin` idea.
- **Claude Code does the CLAUDE.md layering through imports.** Established and native. A session
  in `f5/` loads every CLAUDE.md from `f5/` up to the root, so `N2S/CLAUDE.md` loads without an
  import. Imports may be absolute and may nest four hops deep. An import outside the project,
  such as `~/shared/S/CLAUDE.md`, needs a one-time approval per project.
- **Delete `effective/` after the iteration.** In memory-rendering practice, yes. Under the
  rendered manifests pattern, the rendered output is kept as the audit record. Either is
  established. The plan's choice holds because `SOURCES` plus the pinned commits rebuild it.

### Section 4: the set of files

- **`method.md`, `simulated-user.md`, `reviewer.md`, `planner.md`, `coder.md`.** Ours. The
  established places for agent instructions are CLAUDE.md or AGENTS.md (always loaded), skills
  (`<name>/SKILL.md`, loaded on demand) and subagent files (`agents/<name>.md`). Our files are
  read by our programs, not by Claude Code, so Claude Code's names do not bind us. Keep.
- **`CLAUDE.md` in every layer.** Established. Keep.
- **`feedback/<id>.json` and `items/<id>.json`.** Established as datasets of examples with ids.
  LangSmith and Langfuse store them as datasets of examples, each with inputs, a reference
  output and metadata. Keep one file per entry. Adopt "dataset" and "example" when describing
  them.
- **`workflows/`.** Ours as a folder name. Copier calls the steps that run after scaffolding
  `_tasks`, and the steps that run on update `_migrations`. Keep.

### Section 5: build down

- **`shared` builds a project, steps 1 to 3 (pin, create `N2S/S/`, write the project's first
  workflows).** Established: this is `copier copy`. It renders the template, writes the answers
  file with the commit, and runs `_tasks`. Adopt Copier for these three steps.
- **The project customises its copy of build down.** Established: Copier and cruft both expect
  the project to edit what the template wrote. Copier's `copier update` later brings in a newer
  template with a three-way merge. It renders the old template version, takes the project's diff
  from it, renders the new version, and reapplies the diff with `git apply` and
  `git merge-file`. Conflicts land as inline markers or `.rej` files. This is what the plan needs
  when `shared`'s build down improves after N2S customised its own. The plan does not yet say how
  that update happens. Adopt `copier update`.
- **Steps 4 and 5 (the simulated user builds items; the person approves).** Ours. No scaffolding
  tool generates labelled data. Keep.
- **N2S builds an iteration.** Established as a second, project-owned generator: Nx and
  Turborepo let a workspace define its own local generators. Copier also allows one project to
  apply several templates, each with its own answers file. Keep the project's own build down.
  It is a generator, not a template update.
- **Step 3, build `effective/`, and step 4, check that programs read only from it.** Established
  as render-then-verify. Keep.

### Section 6: build up

- **Iteration to project, with the person's approval.** Established as promoting examples into a
  curated dataset through a review queue. LangSmith adds production runs to a dataset, often via
  an annotation queue. Keep the plan's steps. Adopt "annotation queue" or "review queue" for
  step 3.
- **Project to `shared`, with the person's approval.** Established as inner source: a change to
  a shared library is a pull request to its repository, reviewed by its maintainers (the Trusted
  Committer pattern). Adopt it: step 4 is "merge the pull request and tag a release". The
  project then moves its pin with `copier update` or a manifest bump.
- **Rewrite in general terms, then check that the reviewer still catches the fault from the
  general version alone.** Ours. The nearest established practice is a regression test that
  must pass before a change merges upstream. Keep.
- **Build up as a separate direction from build down.** Established, with one caution. Template
  tools are one-way: Copier, cruft and cookiecutter have no "push back" command. Git subtree is
  the one tool that does both directions in one place: `git subtree pull` brings `shared` in,
  `git subtree push` sends project edits back. Red Hat's *upstream first* rule reverses the
  plan's order: change the shared project first, then carry it downstream. The reason given is
  that changes carried only downstream are hard to land later. The plan's order, prove in the
  iteration and then promote, is the vendor practice that upstream first argues against. It
  fits our case, because "proves general" can only be seen after use. Keep, and keep the time an
  entry spends below `shared` short.

## 1. Scaffolding that stays linked to its template

Only Copier and cruft keep a project linked to its template and merge later template changes
into a customised project. The others scaffold once.

- **Copier** (active; v9.18.2, September 2026). Records answers and `_commit` in
  `.copier-answers.yml`. Users must not edit it by hand. `copier update` does the three-way merge
  described above. It runs `_migrations` on update and `_tasks` after copy and update. One
  project can apply several templates, each with its own answers file (`-a`). Copier recommends
  one template per git repository.
- **cruft** (dormant; last release 2.16.0, December 2024). Adds update to cookiecutter templates.
  Records template URL, commit and variables in `.cruft.json`. `cruft check` fails CI when the
  project is behind. `cruft update` and `cruft diff` apply and show template changes. Has a
  `skip` list for files it must not touch.
- **cookiecutter** (maintained; v2.7.1, March 2026). One-shot. Saves the last answers in a
  replay file in the user's home folder, not in the project. No update.
- **Yeoman** (maintained; yo v7.0.1). One-shot, with a conflict prompt when a generator would
  overwrite a file. Stores generator settings in `.yo-rc.json`. No update from a newer
  generator.
- **Backstage software templates** (active). One-shot. Records each run as a task with its
  inputs. The documentation describes no link back to the template. (Inference: a project made
  this way gets template changes only by hand.)
- **Nx and Turborepo generators.** Nx generators scaffold. `nx migrate` is the update path for
  Nx's own plugins: it writes `migrations.json`, then `--run-migrations` rewrites code. This is
  versioned code migration, not template merge. Turborepo generators (`turbo gen`) are one-shot.
- **GitHub template repositories.** One-shot copy with fresh history. No record of the template
  commit. No update.

What we would adopt: Copier for `shared` → project. Its answers file replaces `shared.lock`.
`copier update` replaces a hand-written update of the project's customised workflows.

## 2. Layered configuration

Every system below merges broad to specific, and the specific layer wins or is read last. They
differ in how they merge and in whether the merged result is ever written down.

- **Claude Code memory.** Managed, user (`~/.claude/CLAUDE.md`), project (`CLAUDE.md`), local
  (`CLAUDE.local.md`). Files from the root down to the working folder are concatenated, broad
  first. Subfolder CLAUDE.md files load when Claude touches a file there. `@path` imports
  expand in place, four hops deep. `.claude/rules/*.md` are unions, and may be scoped to paths.
  `--add-dir` with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` also loads another folder's
  CLAUDE.md and rules. Computed at session start; nothing is written.
- **Claude Code skills.** Enterprise, personal, project, nested and plugin locations. On a name
  clash, enterprise beats personal beats project. Plugin skills are namespaced and never clash.
- **Cursor rules.** Team, project (`.cursor/rules/*.mdc`), user, plus AGENTS.md. All are merged.
  On conflict, team wins, then project, then user.
- **AGENTS.md** (Agentic AI Foundation, Linux Foundation). One file per folder. The file
  nearest the edited file wins. The chat prompt beats all files.
- **git config.** System, global, local, worktree. Read in that order; the last value of a key
  wins. `git config --list --show-origin` prints the result with where each value came from.
- **EditorConfig.** Searches up the folders until a file says `root = true`. Nearer files win
  per property.
- **ESLint, Prettier, TSConfig.** ESLint's flat config is an ordered array of objects; later
  objects override, and shareable configs are packages spread into the array. TSConfig
  `extends` overrides key by key, but `files`, `include` and `exclude` replace whole.
  Prettier's shareable config is a package referenced by name; to change it, a project imports
  it and spreads it. All are computed at run time, with a print command.
- **Kustomize.** A base knows nothing of its overlays. Overlays apply strategic-merge or JSON
  patches. `kustomize build` writes the result, usually piped to `kubectl`. Maintained (v5.8.3).
- **Helm values.** Chart `values.yaml`, then parent chart values, then `-f` files left to right,
  then `--set`. Maps deep-merge; lists replace. `helm template` renders.
- **Nix overlays.** Functions of `final` and `prev` that are composed in order. Each overlay
  modifies the package set the previous ones produced.
- **CSS cascade.** Origin, cascade layers (`@layer`), specificity, then order. Later wins at
  equal weight.

What we would adopt: Claude Code's rule as it stands for the `.md` files (concatenate, specific
last). "Nearest wins" for a repeated id in a data folder. A `SOURCES` record in the
`--show-origin` style. `effective/` is rendered output in the Kustomize sense.

## 3. Shared prompt and agent libraries

Two forms exist. Registries keep prompts as versioned records fetched at run time. Packages keep
them as files installed at a version. Neither layers a project prompt on a shared one. The
established way to customise is to fork or to template.

- **LangSmith prompts.** Each save is a commit with a hash. Tags point at a commit; `staging`
  and `production` move by promotion and keep a rollback history. Code pulls `name:tag` or
  `name:commit`. The public hub allows forking into an organisation.
- **Langfuse prompt management** (active). Each save of a name is a new version. Labels such as
  `production` select the version served. SDKs cache prompts in memory.
- **PromptLayer.** A registry with versions and release labels, in the same style. (Not checked
  in its documentation for this report.)
- **Claude Code plugins and marketplaces.** A marketplace is a git repository with
  `.claude-plugin/marketplace.json`. A plugin carries skills, agents, hooks, commands, MCP
  servers and workflows. Its `version` pins users until it changes; git sources can pin a `ref`
  or `sha`. A CLAUDE.md inside a plugin is not loaded; instructions must go in a skill.
  Projects add their own skills beside plugin skills; namespacing keeps both.
- **OpenAI Agents SDK** (active; v0.23.1). An agent's instructions can be a string or a function
  that builds them at run time. `agent.clone(...)` copies an agent with changed fields. This is
  customisation by copy, in code.
- **DSPy** (active; 3.4.0). A program's optimised prompts and examples are saved per task with
  `save` and `load`. Reuse across tasks means re-optimising on the new task's data.

What we would adopt: tags for released states of `shared` (git tags on the repository, in the
LangSmith style of named pointers). If `shared`'s Claude Code parts should be installable, a
plugin in a marketplace is the established vehicle, but it cannot carry CLAUDE.md.

## 4. Upstreaming (build up)

- **Upstream first** (Red Hat). Every patch goes to the community project before the product.
  Red Hat gives two reasons: the community vets the idea, and side effects show up early. A
  Red Hat kernel developer wrote that a change not accepted upstream has a very hard time
  getting into RHEL.
- **Inner source** (InnerSource Commons). Teams contribute to shared code by pull request.
  Maintainers review. The Trusted Committer pattern names contributors who may review and merge.
  A CONTRIBUTING file states the rules.
- **Vendoring versus forking.** Vendoring copies a dependency into the project at a version; the
  project should not edit it. Forking lets the project edit it, and the edits must be carried or
  sent upstream. Git subtree is vendoring that still allows `git subtree push` upstream.
- **Promoting examples into shared datasets.** LangSmith adds production runs to a dataset,
  often through an annotation queue where a person approves each one. Curated "golden" sets are
  kept as versioned datasets.

What we would adopt: a pull request to `shared` as the approval for project → `shared`, and a
release tag on merge. A review queue for iteration → project.

## 5. Where the plan's layout meets these tools

- **Sibling clone versus pin.** One clone of `shared` serves every project on the machine. Two
  projects pinned to different commits cannot both be satisfied by one checkout. The import in
  CLAUDE.md always reads the current checkout. Established fixes: a submodule per project; a
  workspace manifest with `west update`-style checkout; or one `git worktree` of `shared` per pin.
- **Copier and the sibling clone.** Copier reads the template from a git URL or path at a tag or
  commit. It works with `~/shared` as the source. It writes files into the project; it does not
  serve files at run time. So Copier covers the scaffolded copies (the project's own workflows),
  and the pin question above covers the files read in place.
- **Claude Code and files outside the project.** External imports and symlinked rules need a
  one-time approval. `--add-dir` loads another folder's CLAUDE.md only with an environment
  variable set. Plugins cannot carry CLAUDE.md.
- **Nested repositories.** The plan nests nothing, which avoids the usual submodule costs:
  a separate clone step, a detached HEAD, and commits that must be pushed in two repositories.
- **Package managers.** Prompts and code could ship as a package (pip or npm from a git URL with
  a lock file). This pins well but turns files into installed artifacts, which conflicts with
  reading `~/shared/S/` in place and editing it during build up. For data, DVC and the Hugging
  Face Hub pin dataset revisions; plain JSON files in git already do this at our size.

## Sources

- Copier, updating: https://copier.readthedocs.io/en/stable/updating/
- Copier, settings (`_answers_file`, `_commit`, `_tasks`, `_migrations`, several templates):
  https://copier.readthedocs.io/en/stable/configuring/
- Copier update source (`git apply`, `git merge-file`):
  https://github.com/copier-org/copier/blob/master/copier/_main.py
- cruft: https://cruft.github.io/cruft/ ; https://github.com/cruft/cruft
- cookiecutter: https://github.com/cookiecutter/cookiecutter
- Yeoman: https://yeoman.io/ ; https://github.com/yeoman/yo
- Backstage software templates: https://backstage.io/docs/features/software-templates/
- Nx migrate: https://nx.dev/docs/features/automate-updating-dependencies
- Turborepo generators: https://turborepo.com/docs/guides/generating-code
- GitHub template repositories:
  https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository
- Claude Code memory: https://code.claude.com/docs/en/memory
- Claude Code skills: https://code.claude.com/docs/en/skills
- Claude Code plugin marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Claude Code plugin manifest: https://code.claude.com/docs/en/plugins-reference
- Cursor rules: https://cursor.com/docs/context/rules
- AGENTS.md: https://agents.md/
- git config: https://git-scm.com/docs/git-config
- EditorConfig: https://editorconfig.org/
- ESLint configuration files: https://eslint.org/docs/latest/use/configure/configuration-files
- TSConfig `extends`: https://www.typescriptlang.org/tsconfig/#extends
- Prettier sharing configurations: https://prettier.io/docs/sharing-configurations
- Kustomize glossary: https://kubectl.docs.kubernetes.io/references/kustomize/glossary/
- Helm values files: https://helm.sh/docs/chart_template_guide/values_files/
- Nix overlays: https://nixos.org/manual/nixpkgs/stable/#chap-overlays
- CSS cascade: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascade/Cascade
- Rendered manifests pattern: https://akuity.io/blog/the-rendered-manifests-pattern
- Zephyr west manifests: https://docs.zephyrproject.org/latest/develop/west/manifest.html
- git subtree: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc
- git submodules: https://git-scm.com/book/en/v2/Git-Tools-Submodules
- LangSmith prompts: https://docs.langchain.com/langsmith/manage-prompts
- LangSmith datasets: https://docs.langchain.com/langsmith/manage-datasets-in-application
- Langfuse prompt management: https://langfuse.com/docs/prompt-management/get-started
- PromptLayer prompt registry: https://docs.promptlayer.com/
- OpenAI Agents SDK: https://openai.github.io/openai-agents-python/agents/
- DSPy saving and loading: https://dspy.ai/tutorials/saving/
- Red Hat participation guidelines (upstream first):
  https://redhat.com/en/about/open-source/participation-guidelines
- Red Hat, what is upstream: https://www.redhat.com/en/blog/what-open-source-upstream
- LWN comment on RHEL and upstream: https://lwn.net/Articles/431434/
- InnerSource patterns: https://patterns.innersourcecommons.org/ ; Trusted Committer:
  https://patterns.innersourcecommons.org/p/trusted-committer
