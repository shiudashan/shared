# Survey: who performs and who owns each curation act

Survey date: 2026-10-12.

This survey asks one question about the curation acts of `.claude/grand-plan.md` sections 5 and
6: which actor performs each act in established practice, and which role answers for that actor.
`survey/survey-upstreaming.md` assigns the mechanical acts to a program with no role.
`survey/survey-data-curation.md` assigns the mechanical acts to a new role, the curator. This
survey does not repeat either survey. "Inference" marks every claim that no source states.

## Answer

Established practice splits each mechanical act three ways. A program performs the act. A
platform or infrastructure team builds the program. A named role on the receiving dataset
configures the program and answers for the program's output. The judgement acts (review, accept,
decline) stay with named human roles in every source this survey read.

Practice does not name one curator who performs the mechanical acts by hand. The setup role
exists in every tool (Label Studio's Manager, Labelbox's Data Admin and Project Lead, Argilla's
admin, LangSmith's workspace Editor), but that role configures programs and does not dedupe
entries itself. At small scale, the role that approves also owns the bot: a kernel stable
maintainer runs AUTOSEL; a repository's maintainers own Dependabot's configuration.

Inference for S: S needs no new role. S's coder builds each curation program through S's normal
step, as S's coder builds any program of S. The receiving layer's decision maker owns each
program's operation, as the setup role does in the tools above. The two earlier surveys
reconcile under this reading: `survey-upstreaming.md` names the performer (a program), and
`survey-data-curation.md`'s curator names the owner's duties, which practice places in an
existing role.

| Act | Established performer | Established owner | S role that owns it | Source |
|---|---|---|---|---|
| Collect with author, source, status, version | Program: LangSmith automation rule; Label Studio and Labelbox import | Role that configures the rule or import: LangSmith workspace Editor or Admin; Label Studio Manager; Labelbox Data Admin; Argilla admin | Receiving layer's decision maker; program built by S's coder | LangSmith, Label Studio, Labelbox, Argilla docs; S mapping is inference |
| Remove exact duplicates | Program (pipeline step) | Pipeline owner: dbt group `owner`, Dagster asset `owners`, Spotify's pipeline team | Receiving layer's decision maker; program built by S's coder | dbt, Dagster, Google SRE Workbook; S mapping is inference |
| Cluster near duplicates | Program (pipeline step); Labelbox logic nodes route by consensus | Same pipeline owner; Labelbox workflow editor | Receiving layer's decision maker; program built by S's coder | Labelbox, dbt, Dagster; S mapping is inference |
| Send flagged entries for cleansing review | Program routes the entry: LangSmith rule adds to an annotation queue; Labelbox logic node routes to a review task | Queue or workflow configurer (setup role above) | Receiving layer's decision maker | LangSmith, Labelbox; S mapping is inference |
| Review at the gate | Human reviewer: LangSmith queue reviewers; Label Studio Reviewer; Labelbox Reviewer; kernel stable review committee; GitHub code owners | Same reviewer role | Receiving layer's proposal reviewer | LangSmith, Label Studio, Labelbox, kernel stable rules, GitHub; S mapping is inference, consistent with `survey-upstreaming.md` act 4 |
| Accept or decline | Approver: DAMA-DMBOK2 data owner; LLVM release manager; repository maintainer merging a Dependabot pull request | Same approver | Receiving layer's decision maker (the person on top for `shared`) | DAMA-DMBOK2 via secondary sources, LLVM, GitHub; Linux kernel AI rule for the human on top |
| Commit into the upper dataset and tag a version | Program on the approver's signal: Renovate automerge; LangSmith "Add to Dataset" | Maintainer who enables automerge; reviewer who clicks "Add to Dataset" | Receiving layer's decision maker | Renovate, LangSmith; S mapping is inference |
| Replace the lower copy at the next sync down | Program: Ubuntu auto-sync; Merge-o-Matic for packages with a delta | Ubuntu archive admins (sync over a delta); Ubuntu maintainers supervise merges | Lower layer's coder, as in grand plan section 5 act 5 | Ubuntu project docs; S mapping from `survey-upstreaming.md` |
| Mark a declined entry local | Downstream maintainer edits the record: Debian DEP-3 `Forwarded: not-needed` | Debian package maintainer | Lower layer's decision maker, through the entry's `decided` field | DEP-3; S mapping is inference |

## 1. ML data operations and annotation platforms

**LangSmith.** LangSmith's docs state: "You define an automation by an item type, filter,
sampling rate, and action." An automation rule "adds the trace's inputs and outputs to a
dataset", or adds "the matching run or trace to an annotation queue". LangSmith's docs name no
special role for rule creation. LangSmith's docs gate only the retention toggle: "an admin-only
control"; non-admins "can still create and edit rules". LangSmith defines three workspace roles:
Admin, Editor and Viewer. In an annotation queue, reviewers edit a run "to create a corrected
reference example and click Add to Dataset". The queue's creator sets "the number of reviewers
that must mark an item as Done". LangSmith's docs also state: "Reviewers cannot view the feedback
left by other reviewers."

Finding: LangSmith's rule performs collection and routing. LangSmith's Editor or Admin
configures the rule. LangSmith's queue reviewer performs the gate and the promotion click.

**Langfuse.** Langfuse's role table grants "Create scores, datasets, prompts, or evaluators" to
the Member role. Langfuse describes annotation queues as "built for domain experts to add scores
and comments". Langfuse's queue setup lets the creator "Assign users to the queue". Langfuse's
docs name no curator role.

**Argilla.** Argilla defines three roles: owner, admin and annotator. Argilla's admin may
"Create, configure, update, and delete datasets" only "within assigned workspaces". Argilla's
annotator may only "Provide feedback". Argilla's owner "refers to the root user who created the
Argilla instance".

**Label Studio.** Label Studio defines five roles: Owner, Administrator, Manager, Reviewer and
Annotator. Label Studio's permission matrix gives "Import data", "Export data" and "Configure
project settings" to Manager and above, and gives "Verify annotation results" to Reviewer and
above. Label Studio describes the Reviewer as the role that "Reviews annotated tasks" and the
Annotator as the role that "Labels tasks".

**Labelbox.** Labelbox's permission table gives "Import data/create new datasets in Catalog" to
Admin and Data Admin, "Create new batches" and "create exports" to Admin and Project Lead, and
label review to Reviewer, Team Manager and Project Lead. Labelbox's default workflow runs
"Initial labeling", "Initial review", "Rework" and "Done". Labelbox's logic nodes route data rows
by labeler, consensus average, labeling time and other criteria. Labelbox's docs state: "Data
rows automatically move to the next task only when the previous step is completed."

Finding across section 1: every platform names a setup role (Manager, Data Admin, Project Lead,
admin, Editor) that imports, configures and exports, and a separate reviewer role that verifies.
No platform this survey read uses the job titles "data curator", "data steward", "data engineer"
or "MLOps engineer" as a product role. Scale AI's public docs did not yield a role table, so this
survey omits Scale AI.

## 2. Data governance

**DAMA-DMBOK2.** The book is not open, so this survey quotes secondary sources that cite the
book. The Government of Canada's GCcollab wiki quotes DMBOK2 section 1.3.5: "A steward is a
person whose job it is to manage the property of another person." The same wiki quotes: "Data
Owners are Business Data Stewards who have approval authority for decisions about data within
their domain." A CDMP study guide summarises DMBOK2's split: the owner "has the authority to
approve policies, budgets, and access rights"; the steward "recommends policies and access
rights; executes approved policies" and "escalates unresolved terminology or quality conflicts
to the Data Owner". The same guide lists four DMBOK2 steward types: Business, Technical,
Coordinator and Domain. Secondary sources place the data custodian in IT, responsible for
"storage, security, and backups".

**NIST and CNSSI.** NIST's glossary, citing CNSSI 4009, defines the information owner as the
"Official with statutory or operational authority for specified information" with
"responsibility for establishing the controls for its generation, collection, processing,
dissemination, and disposal". CNSSI 4009-2022 states: "Data stewards enforce policies, and
functional data managers implement the policies and manage day-to-day quality."

Finding: governance practice separates the approver (owner) from the executor (steward or
custodian). DMBOK2 also makes the owner a kind of steward, so one person can hold both duties.
Inference: in S, the decision maker holds the owner's approval, and S's coder plays the
technical steward or custodian who builds and keeps the programs.

## 3. Open-source and dataset maintenance

**Hugging Face.** Hugging Face's dataset card template asks for "Curated by", "Shared by",
"Who are the source data producers?" and "Who are the annotators?". The template's guidance
reads "the people or systems who originally created the data" and "the people or systems who
created the annotations". Hugging Face's Hub lets contributors open pull requests on a dataset
repository; Hugging Face's docs give write-access holders the moderation powers. Hugging Face's
dataset viewer "automatically converts every dataset to the Parquet format" and publishes the
result on a `refs/convert/parquet` branch. Hugging Face's `parquet-converter` bot announces the
conversion in a discussion on each dataset. Finding: Hugging Face runs the bot as a platform
service; the dataset's curators own the dataset's content.

**Debian.** Debian's Developer's Reference tells the package maintainer: "A big part of your job
as Debian maintainer will be to stay in contact with the upstream developers," and "When you
make such fixes, be sure to pass them on to the upstream maintainers as well." DEP-3 records the
forward in the `Forwarded` field and reserves `not-needed` for a patch that "must not be
forwarded upstream". DEP-3 states its purpose: "so that tools (like the Debian Package Tracker)
can display them". The Debian Package Tracker shows an action item for each patch "not yet
forwarded upstream". Debian's wiki sends tracker questions to the debian-qa list. Finding: the
package maintainer files the forward and marks a patch local; the Debian Package Tracker
collects and displays status; Debian's QA team hosts the tracker's discussion channel.

**Ubuntu.** Ubuntu's docs define sync as "the automatic copying of new packages from Debian
unstable". Ubuntu's docs state: "Corresponding Ubuntu packages that carry Ubuntu delta are
excluded from the sync." On request, "archive admins can sync a package from Debian even if the
Ubuntu package carries an Ubuntu delta. In this case, the Ubuntu delta is dropped." Ubuntu's docs
also state: "The Ubuntu Merge-o-Matic (MoM) service automatically performs merges," and "To
complete a merge, interaction and supervision by Ubuntu maintainers are required." Finding:
Launchpad's auto-sync and Merge-o-Matic perform the replacement; Ubuntu archive admins and Ubuntu
maintainers own and supervise the replacement.

**Linux stable.** The kernel's stable rules name AUTOSEL among "the stable team's backporting
tools". LWN describes AUTOSEL as "a tool that is used to find kernel patches that should be
considered for backporting into the stable releases". Sasha Levin, listed with Greg Kroah-Hartman as a STABLE BRANCH maintainer in the kernel's MAINTAINERS file, runs
AUTOSEL and posts each pick to the mailing lists under a `[PATCH AUTOSEL ...]` subject. Sasha
Levin wrote on LKML that AUTOSEL picks get "a longer review cycle" and that AUTOSEL serves "to
complement the work done by maintainers, not replace it". The stable rules give "The review
committee" "48 hours in which to ACK or NAK the patch." The kernel's coding-assistant rules state
"AI agents MUST NOT add Signed-off-by tags" and make the human submitter responsible for "Taking
full responsibility for the contribution." Finding: a stable maintainer owns and runs the
selection bot; the review committee and subsystem maintainers review; a human answers for every
accepted patch.

**LLVM.** LLVM's GitHub docs let a contributor request a backport with "/cherry-pick <commit>";
LLVM's GitHub automation then creates "a pull request ... with the specified commits", or adds a
comment linking the failing job. LLVM's release rules state: "Patches applied to the release
branch may only be applied by the release manager, the official release testers, or the
maintainers with approval from the release manager." Finding: LLVM's bot performs the
cherry-pick; LLVM's release manager approves and owns the release branch. LLVM's docs this survey
read do not name the bot's maintainer; LLVM's infrastructure area team reviews CI/CD access.

Finding across section 3: bots perform the mechanical acts in every project. A maintainer role
(stable maintainer, release manager, archive admin, package maintainer) owns each bot's effect.
Platform teams (Hugging Face, Debian QA, LLVM infrastructure) build and host the shared bots.

## 4. Pipelines owned by a role

**Dependabot.** GitHub's docs state: "You enable Dependabot version updates by checking a
`dependabot.yml` configuration file into your repository." GitHub's docs continue: "When
Dependabot identifies an outdated dependency, it raises a pull request." The maintainer then
checks tests, reviews the changelog, "and then merge it".

**Renovate.** Renovate's docs state: "Renovate will wait for the required tests to pass before
it automerges." Renovate's docs advise: "enable automerge for any dependency update where you
would select "merge" anyway" and "Keep automerge disabled for updates where you want to read the
changelogs or code before the merge." Renovate's docs add that Renovate "can't automerge its own
PR until such a review has happened" when the branch requires reviews.

**GitHub code owners.** GitHub's CODEOWNERS file names "individuals or teams that are responsible
for code in a repository". GitHub requests code owners' review automatically and can "require
approval from a code owner before the author can merge a pull request."

**Data pipelines.** dbt's docs state: "every group has an `owner`", and the owner "Identifies
who is responsible for the group." Dagster's docs require each asset owner to be "an email
address or a team name", because "it's important to know which individuals and teams are
responsible for a given data asset". Google's SRE Workbook reports that at Spotify "a single team
is responsible for the development and operation of the system throughout its entire lifecycle",
and that "event ownership needs to be explicitly defined". The SRE Workbook leaves quality SLOs
to "our internal teams that own the business logic".

Finding: in every case a program performs the act, and a named role (repository maintainer, code
owner, dbt group owner, Dagster asset owner) configures the program and answers for the
program's output. The owner sets how far the program may act alone: Renovate's maintainer
chooses automerge or review per update type.

## Conclusion for S

Sourced finding: practice gives every mechanical act (collect, de-duplicate, cluster, route,
commit, sync) to a program, and gives every program a named owner who configures the program and
answers for the program's output. Practice gives review to a reviewer role and acceptance to an
owner or approver role, and keeps a human on top where a change is hard to undo.

Inference: S's seven roles cover every act. S's coder builds each curation program. The
receiving layer's decision maker owns collect, de-duplicate, cluster, routing and commit, as
LangSmith's Editor, Label Studio's Manager, a stable maintainer or a Dependabot repository's
maintainer owns the equivalent bot. The receiving layer's proposal reviewer reviews flagged
entries and upward entries at the gate. The receiving layer's decision maker accepts or declines;
for `shared`, the person sits on top. The lower layer's coder replaces the local copy at sync
down. The lower layer's decision maker marks a declined entry local. The decision maker also
sets how far each program acts alone, as Renovate's automerge setting does.

Inference: the curator of `survey-data-curation.md` matches the setup role of the annotation
platforms and the steward of DAMA-DMBOK2. DMBOK2 lets the owner hold steward duties, and small
projects (Linux stable, Dependabot users) let the approver own the bot. S's size, tens to
hundreds of entries per generation, sits at the small end, so S folds the curator's duties into
the decision maker. A test would prove this wrong: if the decision maker's curation duties
crowd out the decision maker's approval work in a real generation, S needs the separate role.

## Sources

- LangSmith automation rules: https://docs.langchain.com/langsmith/rules
- LangSmith annotation queues: https://docs.langchain.com/langsmith/annotation-queues
- LangSmith role-based access: https://docs.langchain.com/langsmith/rbac
- Langfuse roles: https://langfuse.com/docs/administration/rbac
- Langfuse annotation queues: https://langfuse.com/docs/evaluation/evaluation-methods/annotation-queues
- Argilla user management: https://docs.argilla.io/latest/how_to_guides/user
- Label Studio roles: https://docs.humansignal.com/guide/admin_roles
- Labelbox roles and permissions: https://docs.labelbox.com/docs/roles-and-permissions
- Labelbox workflows: https://docs.labelbox.com/docs/workflows
- DAMA-DMBOK2 quoted on GCcollab: https://wiki.gccollab.ca/Special:MobileDiff/51466
- CDMP study guide, data stewardship: https://open-exam-prep.com/study-guides/cdmp/data-governance-b/data-stewardship
- CDMP study guide, roles: https://open-exam-prep.com/study-guides/cdmp/exam-overview-dmbok/data-management-organization
- NIST glossary, information owner: https://csrc.nist.gov/glossary/term/information_owner
- NIST glossary, data steward: https://csrc.nist.gov/glossary/term/data_steward
- Hugging Face dataset card template: https://github.com/huggingface/huggingface_hub/blob/main/src/huggingface_hub/templates/datasetcard_template.md
- Hugging Face pull requests and discussions: https://huggingface.co/docs/hub/repositories-pull-requests-discussions
- Hugging Face dataset viewer, Parquet: https://huggingface.co/docs/dataset-viewer/parquet
- Debian Developer's Reference, duties: https://www.debian.org/doc/manuals/developers-reference/developer-duties.en.html
- DEP-3: https://dep-team.pages.debian.net/deps/dep3/
- Debian Package Tracker wiki: https://wiki.debian.org/qa.debian.org/distro-tracker
- Ubuntu merges and syncs: https://ubuntu.com/project/docs/how-ubuntu-is-made/processes/merges-and-syncs
- Linux MAINTAINERS, STABLE BRANCH entry (Greg Kroah-Hartman, Sasha Levin): https://github.com/torvalds/linux/blob/master/MAINTAINERS
- Linux stable kernel rules: https://www.kernel.org/doc/html/latest/process/stable-kernel-rules.html
- Linux coding assistants: https://www.kernel.org/doc/html/latest/process/coding-assistants.html
- LWN on the AUTOSEL rewrite: https://lwn.net/Articles/1020203/
- Sasha Levin on AUTOSEL review, LKML: https://lkml.iu.edu/hypermail/linux/kernel/2011.3/05212.html
- AUTOSEL mail example: https://lists.infradead.org/pipermail/kexec/2025-July/033084.html
- LLVM GitHub backports: https://llvm.org/docs/GitHub.html
- LLVM release process: https://llvm.org/docs/HowToReleaseLLVM.html
- GitHub Dependabot version updates: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates
- Renovate automerge: https://docs.renovatebot.com/key-concepts/automerge/
- GitHub code owners: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- dbt groups: https://docs.getdbt.com/docs/build/groups
- Dagster asset metadata and owners: https://dagster.io/docs/guides/build/assets/metadata-and-tags
- Google SRE Workbook, data processing pipelines: https://sre.google/workbook/data-processing/
