# Upstreaming: who moves a change up a layer, and how

## The answer

Established practice moves a change up in five acts. No new role is needed for any of them.
Each act is a responsibility that one of S's existing roles takes on. Three of the acts are
missing from the current specs.

1. **Tag at birth.** The author of a downstream change records, when the change is made, whether
   it should go upstream. Debian's DEP-3 header has a `Forwarded` field: `no` means "not yet
   sent", `not-needed` means "local by design". Android's common kernel requires a subject
   prefix on every patch: `UPSTREAM:`, `BACKPORT:`, `FROMGIT:`, `FROMLIST:` or `ANDROID:`.
   Fedora asks for a comment above each patch with its upstream status.
   *For S:* the planner states each proposal's upstream status, as a field of the proposal:
   local by design, or a candidate for the layer above. The decision maker confirms it with the
   approval. (Inference: the field's placement in the proposal is ours.)
2. **Track what is carried.** Every local divergence is listed with its status, so unsent
   changes are visible. Debian's database counts patches by `Forwarded` value per release. The
   Debian package tracker warns a maintainer about each patch "not yet forwarded upstream".
   *For S:* the list is data, kept by a program, not a role. The run reviewer reads it at
   monitor, and an unsent candidate older than a set age becomes a finding, as a tracker
   warning does in Debian. (Inference.)
3. **Generalise and propose upstream.** The downstream author rewrites the change for the
   upstream's context and submits it there. The upstream judges it on its own merits. The
   Android kernel README: the commit message "must contain a clear case for why the patch is
   needed and beneficial to the community. Enabling out-of-tree drivers or functionality is not
   a persuasive case."
   *For S:* the upstream change is a proposal in the layer above, written by the planner as a
   delta to that layer's artifact. It then runs through that layer's own step. (Inference: one
   step per layer is ours; it follows from upstream review being the upstream's own review.)
4. **Review and accept upstream.** The upstream's own maintainers review and merge: kernel
   subsystem maintainers, Kubernetes code owners and release managers, InnerSource Trusted
   Committers. The downstream does not approve its own change upstream.
   *For S:* the proposal reviewer, code reviewer and decision maker of the layer above play the
   maintainer. For `shared`, a change touches every project, so it is the hard-to-undo kind; the
   person sits on top of the decision maker there. Fedora's AI policy states the same limit: AI
   may not be the sole or final decider on substantive calls, and accountability for accepting a
   contribution rests with a human. (The placement is our inference.)
5. **Drop the local copy.** Once upstream releases the change, the downstream takes upstream's
   version and deletes its own. Ubuntu requests a sync when its delta "is no longer needed
   because it has been merged in Debian or upstream", and the delta is then dropped. pnpm fails
   an install by default when a recorded patch no longer applies or goes unused.
   *For S:* this is the next sync down. The lower layer's coder replaces its customised copy
   with the upstream text and removes the entry from the list of act 2. Sync's three-way merge
   will often conflict here, because the general wording differs from the local wording; the
   conflict is resolved in favour of upstream. (Inference.)

If upstream rejects the change, the downstream says so in its record. Android: a rejected patch
must not keep the `FROMLIST:` tag "to try to hide this fact"; it becomes `ANDROID:`.
*For S:* a rejected upstream proposal turns the change's status to local by design.

The plan's existing curation activity (`step.md`, Retrospective and curation) is acts 3 to 5
applied to labels only. The five acts extend it to specs, prompts and code.

What is missing from the specs today: act 1 (the upstream status on a proposal), act 2 (the list
of carried changes and its finding), and act 5 (dropping the local copy after upstream
releases). Acts 3 and 4 need no new text beyond saying that the upstream proposal enters the
upper layer's step.

## 1. Code and documents: how changes move up

**Upstream first (Red Hat; Linux kernel; Android).**
- Red Hat follows "a longstanding practice of doing work upstream first". Its reason: shipping a
  fix downstream first is "usually more work in the long run to carry those patches back to the
  project", because upstream moves on meanwhile.
- The kernel's stable rules: a patch "or an equivalent fix must already exist in Linux mainline
  (upstream)". The stable tree takes only what mainline already holds.
- The Android common kernel ranks the options. "BEST: Make all of your changes to upstream
  Linux." "LESS GOOD: Develop your patches out-of-tree", which is "very unlikely to be accepted"
  unless coordinated with the kernel team.
- Who: the change's author writes upstream; the downstream takes it back by cherry-pick.
- For S: S cannot be fully upstream first, because "general enough" shows only after use. The
  earlier survey noted this (`survey-layered-templates.md`, section 6). What S can take is the
  short life of the local copy, and the tag that says from the start where a change belongs.

**Downstream distributions carrying patches (Debian, Ubuntu, Fedora).**
- Debian keeps each change to an upstream source as a separate patch file in a series, applied
  by quilt. DEP-3 puts a header on each patch. `Origin` says where it came from: `upstream`,
  `backport`, `vendor` or `other`. `Forwarded` says whether it was sent: any value other than
  `no` or `not-needed` means it was. `Applied-Upstream` records the upstream version or commit
  that holds it. `Bug` points to the upstream bug. `Last-Update` dates the header.
- Fedora asks for a comment above each patch about its upstream status, with a link to the
  upstream bug. A Fedora-only patch says so. Fedora's reason: it helps "ensure that Fedora is
  acting as a good FLOSS citizen" and shows which patches will vanish with a new upstream
  release.
- Ubuntu takes Debian's packages. A package with no Ubuntu delta is synced automatically. A
  package with a delta is merged, with Merge-o-Matic doing the mechanical part and an Ubuntu
  maintainer supervising. When Debian or upstream adopts the change, a sync is requested and the
  delta is dropped.
- Who: the package maintainer authors, tags, forwards and later drops each patch. Trackers are
  programs.
- For S: DEP-3's fields are a ready-made record for each customisation a lower layer carries.
  `Origin` maps to which layer the change came from; `Forwarded` to the upstream status;
  `Applied-Upstream` to the commit of the upper layer that took it.

**Forks and backports (kernel stable; Android; Kubernetes).**
- A backport carries a change from upstream to an older line. Android tags an unchanged
  cherry-pick `UPSTREAM:` and a modified one `BACKPORT:`, with the changes described under the
  cherry-pick line. The kernel's stable rules ask any deviation from the original to be
  "clearly documented and justified".
- Kubernetes: the change merges on `master` first. The contributor who wrote it opens the
  cherry-pick for each supported branch. Code owners approve, and release managers give the
  final, branch-specific approval.
- For S: backports run downward, so they belong to sync. They matter here for one rule: the
  downstream copy records the upstream commit it came from, and how it differs.

**Inner source (InnerSource Commons patterns).**
- **Trusted Committer:** an upstream-side role. Its scope "is up to each project and its
  maintainers". It is chosen from frequent contributors and active helpers.
- **30 Day Warranty:** for a receiving team that resists contributions. The contributing team
  "consents to provide bug fixes to the receiving team" for a period after the code goes into
  production.
- **Contracted Contributor** and **Gig Marketplace:** these settle whose time pays for upstream
  work. A contract between contributor, line manager and a governance office caps the time; a
  gig site posts upstream tasks with the skills and time they need.
- For S: the Trusted Committer is the upper layer's reviewers and decision maker. The warranty
  maps to routing regressions an upstreamed change causes elsewhere back to the layer that sent
  it (inference). The time questions do not arise for agents, so those two patterns do not bind
  S.

**Monorepo shared libraries and golden paths (Spotify).**
- Spotify calls a golden path "the 'opinionated and supported' path to 'build something'". The
  platform organisation maintains it. Feedback from engineers who follow it is "gold nuggets for
  the Platform organisation". Spotify describes no formal process for teams to propose changes
  to the path.
- For S: `shared` is S's golden path. The source gives no upstream procedure to copy.

**Template back-contribution (Copier, cruft, Backstage).**
- None of these tools has a command to push a project's change back into the template
  (`survey-layered-templates.md`, sections 1 and 6). Back-contribution is an ordinary pull
  request to the template's repository. `cruft check` fails CI when a project is behind its
  template; that measures lag, not unsent changes.

**Kustomize components.**
- A component is "a special type of kustomization that allows one to define reusable pieces of
  configuration logic". Several overlays opt into it. It sits between base and overlay: a piece
  shared by some variants, not all.
- For S: a change general to some projects but not every project has a home of this kind. The
  plan has none today. (Inference; whether S needs it depends on how many projects S serves.)

## 2. Roles in upstreaming

Each established role maps onto an S role. (The mapping is our inference.)
- The contributor, or patch author, writes the change, tags its upstream status and forwards
  it. In S: the planner writes the upstream proposal, and the coder writes the change.
- The downstream maintainer carries patches, decides which to forward, and drops them later. In
  S: the decision maker of the lower layer decides; the coder drops the copy at the next sync.
- The upstream maintainer, Trusted Committer or code owner reviews and merges in the upstream's
  interest. In S: the proposal reviewer, code reviewer and decision maker of the upper layer.
- The release manager, or stable maintainer, approves what enters a release line. In S: the
  decision maker at step 7.
- The patch tracker lists carried patches and their status, and warns. In S: a program and a
  data type, read by the run reviewer.

How each established role works, with its source:
- **Deciding a change is general enough.** The downstream author decides first, by the tag
  (DEP-3 `not-needed` versus `no`; Android `ANDROID:` versus `FROMLIST:`). The upstream decides
  last, by accepting or not. The Android README sets the bar: a clear case that the change
  benefits the community, not only the downstream.
- **Upstream review.** Kernel trailers record who did what: `Reviewed-by:` states the patch was
  reviewed and found acceptable; `Acked-by:` is a lighter assent from someone responsible for
  the code; `Tested-by:` records a test. The stable review committee has 48 hours to ACK or NAK
  each patch.
- **Dropping the local copy.** Ubuntu: request a sync, and the delta is dropped. Debian: the
  patch is removed from the series once the new upstream version holds it; `Applied-Upstream`
  records where. pnpm: a patch that no longer applies fails the install unless
  `allowUnusedPatches` is set.

New role? No established practice adds a separate "upstreamer". The author and the maintainers
on each side do it. The one job not held by a person in practice is the patch tracker, and it is
a program.

## 3. Cadence and triggers

- **Event-driven, at birth.** The kernel's preferred route is a `Cc: stable@vger.kernel.org`
  tag added when the fix is written; once it lands in mainline it "is picked up automatically".
  DEP-3 and Android tags are written when the patch is.
- **Periodic sweeps.** The kernel stable team also runs AUTOSEL, a tool that selects candidate
  commits not tagged for stable. Since 2025 it uses an LLM, and its reasoning appears in the
  posted patches with a warning that it may be wrong. The stable maintainers still ACK or NAK
  each one.
- **Deadlines tied to releases.** Ubuntu syncs from Debian automatically only from the opening
  of a release until the Debian Import Freeze. Kubernetes cherry-picks must be approved before
  a patch release's deadline, or roll to the next one.
- **How long local patches live.** No source sets a maximum age. The sources say why short is
  better: Red Hat and Fedora both name the cost of forward-porting a carried patch at every
  upstream release.
- **Metrics.** Debian publishes counts per release. In Debian's development release (sid), of
  70,913 patches, 8.8% are forwarded, 65.0% not yet forwarded, 24.0% need no forwarding, and
  2.2% have an invalid value. Ubuntu counts packages that carry a delta, since those leave the
  automatic sync.
- For S: the plan says upstream "runs periodically, followed at once by sync". Practice uses
  both a tag at birth and a periodic sweep. One trigger is ours alone: the end of a generation,
  since in-iteration parts die then, and an unsent candidate is lost with them. (Inference.)
  Debian's 65% suggests that without a tracker and a sweep, most carried changes are never sent.
  (Inference from the numbers.)

## 4. Agentic and AI-driven equivalents (2025–2026)

- **Agents that propose upstream patches.** Google DeepMind's CodeMender "upstreamed 72
  security fixes to open source projects" in about six months. A critique agent checks for
  regressions first. Then "all patches generated by CodeMender are reviewed by human researchers
  before they're submitted upstream."
- **Automated selection for backports.** AUTOSEL (above): an LLM proposes, stable maintainers
  decide.
- **Bots that close the loop downstream.** Renovate and Dependabot open pull requests that move
  a project to a newer upstream version. Kubernetes' Prow bot opens cherry-pick pull requests on
  `/cherry-pick`. All of these run downward; they are the act 5 side.
- **Rules for AI contributions upstream.**
  - Linux kernel: "AI agents MUST NOT add Signed-off-by tags." The human reviews the code and
    takes "full responsibility for the contribution". The trailer is `Assisted-by: LLM [TOOL]`.
  - LLVM: "there must be a human in the loop". A contribution should be "worth more to the
    project than the time it takes to review it". The policy "bans agents that take action in our
    digital spaces without human approval".
  - Fedora (October 2025): the contributor is accountable; AI may not be the sole or final
    decider on substantive calls; disclosure by an `Assisted-by:` trailer.
  - GitHub's Copilot coding agent: only users with write access can trigger it; it pushes only
    to its own `copilot/` branch; the user who asked for the pull request cannot approve it.
- **Agents generalising project-specific changes.** No published engineering practice found.
  The nearest is research: Agent Workflow Memory (Wang et al., 2024) induces "commonly reused
  routines, i.e., workflows" from past tasks, and reports that they generalise across tasks,
  websites and domains. Teams sharing Claude Code skills move a skill from a project into a
  plugin marketplace by pull request; the sources found are blogs, not documented procedure.
- For S: the published pattern is one shape everywhere. An agent proposes the upstream change,
  agents check it, and a human on the upstream side accepts it. S's rule that no role reviews
  its own artifact already matches GitHub's "requester cannot approve". The `Assisted-by:`
  trailer is a ready convention for marking which role produced an upstreamed change.

## Sources

- DEP-3, patch tagging guidelines: https://dep-team.pages.debian.net/deps/dep3/
- Debian UDD patch statistics: https://udd.debian.org/patches
- Debian package tracker: https://tracker.debian.org/
- Fedora, patch status: https://docs.fedoraproject.org/en-US/packaging-guidelines/PatchUpstreamStatus/
- Fedora, staying close to upstream: https://fedoraproject.org/wiki/Staying_close_to_upstream_projects
- Fedora, AI-assisted contributions policy: https://docs.fedoraproject.org/en-US/council/policy/ai-contribution-policy/
- Ubuntu, merges and syncs: https://documentation.ubuntu.com/project/how-ubuntu-is-made/processes/merges-and-syncs
- Ubuntu, request a sync: https://canonical-ubuntu-project.readthedocs-hosted.com/contributors/request-a-sync
- Red Hat, what is upstream: https://www.redhat.com/en/blog/what-open-source-upstream
- Linux kernel, stable rules: https://www.kernel.org/doc/html/latest/process/stable-kernel-rules.html
- Linux kernel, submitting patches (trailers): https://www.kernel.org/doc/html/latest/process/submitting-patches.html
- Linux kernel, AI coding assistants: https://www.kernel.org/doc/html/latest/process/coding-assistants.html
- AUTOSEL with LLMs: https://www.phoronix.com/news/AI-Help-Backporting-Linux-Patch ;
  https://thenewstack.io/how-ai-helps-maintain-the-linux-kernel/
- Android common kernels: https://source.android.com/docs/core/architecture/kernel/android-common
- Android common kernel README (patch tags): https://android.googlesource.com/kernel/common/+/refs/heads/android16-6.12/README.md
- Kubernetes cherry-picks: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-release/cherry-picks.md
- InnerSource patterns: Trusted Committer https://patterns.innersourcecommons.org/p/trusted-committer ;
  30 Day Warranty https://patterns.innersourcecommons.org/p/30-day-warranty ;
  Contracted Contributor https://patterns.innersourcecommons.org/p/contracted-contributor ;
  Gig Marketplace https://patterns.innersourcecommons.org/p/gig-marketplace
- Spotify, golden paths: https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem
- Kustomize components: https://kubectl.docs.kubernetes.io/guides/config_management/components/
- pnpm patch: https://pnpm.io/cli/patch
- Renovate: https://docs.renovatebot.com/ ; Dependabot version updates:
  https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates
- LLVM AI tool policy: https://llvm.org/docs/AIToolPolicy.html
- GitHub Copilot coding agent, risks and mitigations: https://docs.github.com/en/copilot/concepts/agents/coding-agent/risks-and-mitigations
- CodeMender: https://deepmind.google/discover/blog/introducing-codemender-an-ai-agent-for-code-security/
- Agent Workflow Memory: https://arxiv.org/abs/2409.07429
- Earlier surveys in this folder: `survey-layered-templates.md`, `survey-process-terms.md`.
