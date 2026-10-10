# Industrial practice for one improvement step

Section 2.2 holds up as a flow. Five of its details came from notes that said only what to
survey. Industry does each of them a specific way:

- Priority is cost of delay divided by duration, from rough relative estimates. Industry
  refines an estimate only where the refinement could change the order. It does not refine
  every estimate several times.
- A proposal reaches the decider with the reviews, a summary of the disagreements, and a
  proposed disposition (approve, postpone or reject). "Only passed proposals reach the person"
  is not the practice. The author withdraws a proposal; the decider rejects or postpones it.
- Each artifact has its own reviewer. AI reviewers from every vendor are advisory. The
  approving party is someone other than the author.
- The established name for the role that runs the system is a *user simulator* (for agents)
  or a test driver (fuzzer, monkey, property-based or model-based generator). Deciding whether
  a run went wrong is a separate job: the *test oracle*. "Developer = user" is not an
  established term.
- A change that fails before merge is dropped from the merge queue, and the remaining changes
  are re-tested without it. After release, a failed change is reverted first. Run results feed
  the next cycle as tracked items with owners.

This survey does not repeat `survey-development-flow.md` (the order of steps, the proposal
states, FCP dispositions, canary against control, ITIL standard change) or
`survey-change-kinds.md` (the check per kind).

## Section 2.2 rewritten as industrial practice

**2.2 Incremental development: one step of S, from v to v+1.**

A step starts from run records. One end-to-end run serves two steps: the run that validates
v+1 is the run the next step reviews. Before the first step, the simulated user runs M.f.v on
the items once.

The simulated user is a *user simulator*: a model that plays the user and drives M.f.
*Source:* τ-bench ("a user (simulated by language models)"); Anthropic's agent-eval guide
("a second LLM to simulate the user"). In industry the system is also run by developers'
tests, by testers in exploratory sessions, by staff using it (dogfooding), and by input
generators (fuzzers, monkeys, property-based and model-based tools). Who judges a run is a
separate question, the test oracle, and belongs to the run reviewer. *Source:* ISTQB "test
oracle"; Barr et al. 2015. That one user simulator is the only driver of M.f is *ours*.

1. **Review the runs.** The run reviewer reads the run records of M.f.v and writes findings.
   Each finding names the symptom it rests on. The run reviewer combines graders: code checks
   where a check exists, a model grader where it does not, and the person for calibration.
   The model grader is checked against the person's grades.
   *Source:* Anthropic ("code-based, model-based, and human"; "LLM-as-judge graders should be
   closely calibrated with human experts"); the test-analyst role in ISTQB; Scrum Sprint
   Review. Findings from a failed release or a regression enter here as tracked items, each
   with an owner. *Source:* Google SRE postmortems ("All action items have both an owner and
   a tracking number").
2. **Propose.** The planner writes a change proposal for the findings: why, the delta to M.p,
   the design, the tasks, the kind and the check. For each proposal the planner estimates
   three relative quantities: the value of the change, its time criticality, and the risk it
   removes or the option it opens. Their sum is the cost of delay. The planner divides it by
   the relative size of the change. The ratio orders the proposals, highest first.
   *Source:* Reinertsen's cost of delay; CD3 (Black Swan Farming); WSJF (SAFe: "time
   criticality, risk reduction and/or opportunity enablement, and job size").
   Estimates are relative scores or ranges, not points. A confidence factor discounts a
   weakly supported upside. *Source:* RICE (Intercom: 100%, 80%, 50% confidence); Hubbard's
   calibrated 90% intervals.
   The planner refines an estimate only when a better value could change the order. It does
   not refine every estimate. *Source:* Hubbard's value of information ("The vast majority of
   variables had an information value of zero"); CD3 "works perfectly well enough with noisy
   inputs".
   Technical-debt proposals are valued by how often the code is changed: debt in code that
   is touched often comes first. *Source:* CodeScene hotspots; Fowler's "interest payments".
   The order is recomputed every step. *Source:* SAFe ("priorities must be continuously
   updated").
   That an AI planner does all this is *ours*. No AI coding agent publishes a prioritisation
   method.
3. **Review the proposals.** The proposal reviewer is never the planner. It checks each
   proposal against M.p and the method, checks that the proposal's check can decide it, and
   checks the estimates behind the order. The planner revises the proposal in place and
   records what changed. Review ends when further review is unlikely to change the design
   much; there is no fixed number of rounds.
   *Source:* Rust RFC ("make changes as new commits ... explaining your changes"); Google
   design docs (review until "further reviews are unlikely to require major changes"); KEP
   reviewers distinct from authors.
   The planner may withdraw a proposal. The reviewer does not reject; it recommends.
   *Source:* PEP 1 and KEP (withdrawn by the author; rejected by the decider).
   Every proposal that is not withdrawn reaches the person with: the proposal, the reviews, a
   summary of the remaining disagreements, and a recommended disposition (approve, postpone or
   reject). *Source:* Rust (a summary comment and a proposed disposition before the final
   comment period); PEP 1 (the author documents "dissenting opinions"); HashiCorp RFCs (dropped
   ideas stay in the document with the reason).
   Review depth follows reversibility. A change that is easy to undo gets a light review.
   *Source:* Amazon's Type 1 and Type 2 decisions; AWS Well-Architected ("hours not days").
4. **Decide.** The person reads the proposals in order, with their reviews and recommended
   dispositions, and gives feedback. S returns to step 2 with it. When the person has no more
   feedback, the person approves some proposals and postpones the rest to the backlog.
   *Source:* `survey-development-flow.md`. The person's feedback and approvals become
   in-iteration data (*ours*).
5. **Build.** The coder builds the approved changes on a branch.
6. **Verify.** On the branch, without an end-to-end run: each change's own check passes, and
   the fast, reliable regression tests and evals pass. These are the required checks before
   merge. *Source:* GitHub required status checks; Software Engineering at Google, ch. 23
   (presubmit runs "only fast, reliable ones").
   A code reviewer other than the coder reviews the diff in a fresh context. Its findings are
   advisory; it neither approves nor blocks. *Source:* Claude Code code review ("don't approve
   or block your PR"); GitHub Copilot ("Comment" review by default); Codex ("they don't replace
   tests, branch protections, or required approvals").
   Changes join a merge queue, each tested on top of the ones ahead of it. A change that fails
   is removed, goes back to the backlog with the reason, and the changes behind it are
   rebuilt and re-tested without it. *Source:* GitHub merge queue.
7. **Validate.** An end-to-end run. The simulated user runs the candidate v+1 (canary) and
   the current v (control) on the same items at the same time. The run reviewer compares them
   on a few metrics fixed before the run, and gives pass, marginal or fail.
   *Source:* Software Engineering at Google, ch. 14 (larger tests run after submit and "as
   part of the release process"); Google SRE Workbook, Canarying Releases ("perhaps no more
   than a dozen" metrics); Spinnaker Kayenta (weighted score; Pass, Marginal, Fail). These
   run records are the ones the next step reviews in step 1.
8. **Release.** The person reads the comparison and approves the release. S merges the
   deltas into M.p, writes the changelog entry, and tags M.p.v+1 and M.f.v+1 together. A
   released version is never changed.
   A failed release is reverted first, then diagnosed: rollback returns to the tag of v.
   *Source:* Software Engineering at Google, ch. 23 ("Rolling a change back is often the
   fastest and safest route"); LLVM ("Any time you learn of a serious problem with a change,
   you should revert it"). Where a change sits behind a switch, the switch is turned off
   instead. *Source:* Feature Toggles (Hodgson).
   If the person does not approve, v stays current, and the comparison's findings enter the
   next step's review as tracked items.
   The person's release approval stays while the automatic reviewers are uncalibrated. DORA
   found that heavy external approval does not lower change failure, and recommends peer
   review plus automated checks. *Source:* DORA, Streamlining change approval. Making release
   automatic per kind of change is covered in `survey-development-flow.md`.
9. **Retrospective.** S improves S's own in-iteration parts from what the step showed.
10. **Elevate.** S moves in-iteration content that proved general up to in-project, with the
    person's approval. *Ours.*

Who reviews what:
- runs: the run reviewer (industry: test analyst, graders);
- proposals: the proposal reviewer (industry: design reviewers; approvers decide);
- code: the code reviewer (industry: peer reviewer, code owner);
- releases: the person (industry: change authority).
No author approves its own artifact. *Source:* ISTQB independence of testing; NIST SP 800-53
AC-5; PCI DSS 6.5.4; SLSA source level 4 ("two or more trusted persons"); GitHub ("approved by
someone other than the person who pushed it").

## 1. Prioritising proposed changes

**Answer.** Order by cost of delay divided by duration. Estimate roughly and in relative
terms. Count risk reduction as value. Discount by confidence, or use ranges. Re-order every
cycle. Refine an estimate only where it could change the order.

**Cost of Delay.** Black Swan Farming: "Cost of Delay is a way of communicating the impact of
time on the outcomes we hope to achieve." Formally, "the partial derivative of the total
expected value with respect to time." Reinertsen: "If you only quantify one thing, quantify the
cost of delay." (Seen as the epigraph of SAFe's WSJF page; the book's page is not checked.)

**CD3.** Divide the cost of delay "by some estimate of duration"; "the higher the resulting
score, the higher the priority." The method "works perfectly well enough with noisy inputs on
the denominator."

**WSJF (SAFe).** "WSJF is calculated as the cost of delay divided by job duration." Cost of
delay is the sum of "relative user and business value", "time criticality", and "risk
reduction and/or opportunity enablement". "In systems with fixed resources, job size is a good
proxy for duration." Scores use modified Fibonacci numbers, and teams "set the smallest item
to a one". "Using this algorithm at PI boundaries continuously updates the job's priorities."
A PI is SAFe's planning cycle of 8 to 12 weeks.

**Risk-adjusted value.** SAFe counts risk reduction inside the cost of delay: "Does it reduce
the risk of this or a future delivery?" "What else does this do for our business?"

**RICE (Intercom).** Reach × Impact × Confidence / Effort. Impact: "3 for 'massive impact', 2
for 'high', 1 for 'medium', 0.5 for 'low', and finally 0.25 for 'minimal'." Confidence: "100% is
'high confidence', 80% is 'medium', 50% is 'low'." And: "RICE scores shouldn't be used as a
hard and fast rule."

**ICE.** Impact, Confidence, Ease, each 1 to 10. Unverified at a primary source; the original
GrowthHackers page is gone. RICE is ICE with Reach added.

**Opportunity scoring (Ulwick, Outcome-Driven Innovation).** "Market opportunity = importance +
max(0, importance – satisfaction)." It ranks needs that are important and unmet.

**Expected value and value of information (Hubbard, *How to Measure Anything*).** State each
uncertain input as a calibrated 90% range. "For a well-calibrated estimator, the true value
will lie in her 90% CI roughly 90% of the time." Simulate the decision: "The simplest tool for
measuring such risks accurately is the Monte Carlo (MC) simulation." Then "compute the value of
additional information" for each variable, and measure only the high-value ones. "The vast
majority of variables had an information value of zero." (Quoted from a summary of the book.)

**Technical debt.** CodeScene: "Low code health in a development hotspot is expensive.
Prioritize improvements here." A hotspot is code "you – as an organization – have to work with
often." Fowler: "crufty but stable areas of code can be left alone", while "areas of high
activity need a zero-tolerance attitude to cruft".

**Uncertainty.** Industry handles it four ways. Relative scores (WSJF). A confidence discount
(RICE). Calibrated ranges with value of information (Hubbard). Re-estimation each cycle (SAFe).
Shape Up turns the question around: "Estimates start with a design and end with a number.
Appetites start with a number and end with a design." McConnell's cone of uncertainty (early
estimates span about 0.25× to 4×) is unverified at the primary source.

**AI agents.** Nothing published. Linear's triage AI suggests "teams, projects, assignees, and
labels", not priority. One research tool wraps classic methods (AHP, MoSCoW) with an LLM
(arXiv 2405.01564). No coding agent (Claude Code, Codex, Copilot, Devin, Factory) documents a
method for ranking a backlog.

**Replacement wording for step 2.** See step 2 above.

## 2. Reviewing and revising proposals before the decision

**Answer.** Reviewers are not the author. The author revises in place, as often as needed.
Review ends when it stops changing the design. The author may withdraw; the decider rejects
or postpones. The decider gets the document, a summary of the discussion with the dissent,
and a proposed disposition. Heavy review is kept for changes that are hard to undo.

**Google design docs.** Light form: "sending out the doc to the (wider) team-list ...
Discussion then primarily happens in comment threads." Heavy form: "formal design review
meetings in which the author presents the doc". Review ends when "further reviews are unlikely
to require major changes to the design".

**Uber RFCs.** "Have a few, select people approve this plan before starting work." Approvers
"can be senior engineers, people on a team who will use the feature". Anyone on the domain
mailing list may comment. No rule for rounds or rejection.

**Rust RFCs.** "RFCs rarely go through this process unchanged." The author should "make changes
as new commits to the pull request, and leave a comment ... explaining your changes." "For RFCs
with lengthy discussion, the motion to FCP is usually preceded by a summary comment."
"Postponed pull requests may be re-opened when the time is right."

**Kubernetes KEPs.** "The approvers are the individuals who decide when to move this KEP to the
`implementable` state." "`rejected`: The approvers and authors have decided that this KEP is not
moving forward." "`withdrawn`: The authors have withdrawn the KEP."

**Python PEPs.** "PEP authors are responsible for collecting community feedback". "The PEP
author is responsible for building consensus within the community and documenting dissenting
opinions." The PEP-Delegate "will then have the authority to approve or reject". Withdrawn
"means that the PEP author themselves has decided that the PEP is actually a bad idea".

**Oxide RFDs.** States: prediscussion, ideation, discussion, published, committed, abandoned.
Review is in a pull request; "you decide when to open the pull request, and you decide when to
merge it." Abandoned: "an idea is found to be non-viable". No separate decider.

**Amazon.** "The great memos are written and re-written, shared with colleagues who are asked
to improve the work, set aside for a couple of days, and then edited again with a fresh mind."
Meetings open with silent reading "in a kind of 'study hall.'" PR/FAQ: "A small group of about
10 contributors makes sense for the first few drafts." "If the executive team finds the idea
promising, multiple subsequent drafts and review meetings will follow." Type 1 decisions are
made "methodically, carefully, slowly"; "Type 2 decisions can and should be made quickly".
"Most decisions should probably be made with somewhere around 70% of the information you wish
you had."

**HashiCorp RFCs.** "Status: WIP | In-Review | Approved | Obsolete". Abandoned ideas are kept in
sections "that make it clear they're abandoned".

**ADRs (Nygard).** "proposed" until agreed, then "accepted"; a reversed decision is kept and
marked "superseded".

**Replacement wording for step 3.** See step 3 above. The change from the draft: the reviewer
recommends instead of filtering, and the person sees every proposal that was not withdrawn.

## 3. Separate reviewers by artifact

**Answer.** Each artifact has its own reviewer with its own authority. Test results go to test
analysts and graders. Designs go to design reviewers and approvers. Code goes to peer
reviewers and code owners. Releases go to a change authority. No author is the only approver.
AI reviewers are advisory in every vendor's product.

**Runs and test results.** ISTQB, independence of testing: "Separation of responsibilities,
which encourages the accomplishment of objective testing." The ISTQB levels of independence
and the test-analyst definition are unverified at the primary source.

**Designs.** AWS Well-Architected: "a lightweight process (hours not days) that is a
conversation and not an audit." It recommends that builders "continually review their
architecture, rather than holding a formal review meeting". TOGAF's Architecture Board is
unverified (behind a login).

**Code.** Google: reviewers "should favor approving a CL once it is in a state where it
definitely improves the overall code health". Software Engineering at Google, ch. 9: "Owners act
as gatekeepers for their particular directories", plus a readability approval. GitHub: "Code
owners are automatically requested for review".

**Releases.** DORA: external change approval has "a negative impact on software delivery
performance", and "no evidence was found to support the hypothesis that a more formal, external
review process was associated with lower change fail rates." ITIL 4's change authority is
unverified at the primary source.

**Separation of duties.** NIST SP 800-53 AC-5: consider "the appropriateness of a single
individual performing multiple critical roles." PCI DSS 6.5.4: "Roles and functions are
separated between production and pre-production environments" (secondary copy). SLSA: "Changes
in protected branches MUST be agreed to by two or more trusted persons". GitHub: "the most recent
reviewable push must be approved by someone other than the person who pushed it."

**AI agents.** Claude Code subagents: "Each subagent runs in its own context window with a
custom system prompt, specific tool access, and independent permissions"; the example
`code-reviewer` has read-only tools. Claude Code code review: findings "don't approve or block
your PR". Codex: "Code review rules guide Codex; they don't replace tests, branch protections,
or required approvals." Copilot code review leaves "a 'Comment' review", so it does not "count
toward required approvals". Copilot coding agent: the requester's "approval ... won't count".
Research systems give one role per artifact: MetaGPT's "Product Manager, Architect, Project
Manager, Engineer, and QA Engineer"; ChatDev splits "code review (static testing) and system
testing (dynamic testing)".

**Replacement wording.** The "Who reviews what" list after step 10 above.

## 4. The one who runs the system to find problems

**Answer.** Industry has two jobs here. One drives the system: developers' tests, testers,
staff using it, or an input generator. The other judges the result: the test oracle. For
conversational agents the driver is called a user simulator. Machines automate driving well.
Judging stays with people except where a crash, a property, a metric or a calibrated grader
can decide.

**Testers.** Kaner: exploratory testing treats "test-related learning, test design, test
execution, and test result interpretation as mutually supportive activities". Bach:
"Exploratory testing is simultaneous learning, test design, and test execution." A session
"often begins with a charter, which states the mission".

**Dogfooding.** "The practice of using one's own products or services" (secondary source; the
Microsoft origin is reported, not checked).

**Random and generated inputs.** ISTQB (glossary v3.1, through a secondary copy): monkey testing
is "a random selection from a large range of inputs and ... randomly pushing buttons, ignorant
of how the product is being used"; random testing selects cases "to match an operational
profile". Android Monkey generates "pseudo-random streams of user events", repeatable by seed.
libFuzzer is "coverage-guided"; AFL keeps inputs that change "program control flow". OSS-Fuzz
"runs fuzzers ... and privately alerts developers". Google uses LLMs to write fuzz targets: "we're
able to increase the code coverage ... without manually writing additional code." QuickCheck:
properties "can be automatically tested on random input". Hypothesis lets the tool "randomly
choose which of those inputs to check." GraphWalker "reads models in the shape of directed graphs
and generates test paths from them".

**Production experiments.** Chaos Monkey is "randomly terminating instances in production".
Principles of Chaos: "Try to disprove the hypothesis by looking for a difference in steady
state" between control and experiment.

**Test selection.** Facebook's predictive test selection learns which tests to run "from a large
dataset of historical test outcomes". Google TAP is unverified at the primary source.

**User simulators.** τ-bench: "a user (simulated by language models)" talking to "a language
agent". Anthropic: agent evals "often require a second LLM to simulate the user", and combine
"code-based, model-based, and human" graders.

**The oracle.** ISTQB: "A source used to determine expected results to compare with the actual
result" (secondary copy). Barr et al.: the oracle problem is "the challenge of distinguishing the
corresponding desired, correct behaviour from potentially incorrect behavior".

**Replacement wording.** The paragraph before step 1 above. It drops "developer = user" and
"automation that selects inputs at random often replaces the developer". Industry does not say
the second; automation runs beside people.

## 5. Verify, validate and release

**Answer.** Before merge, fast and reliable checks run on the branch, and a peer reviews. Larger
end-to-end tests run after merge and at release. A release is compared, canary against control,
on a few metrics. Approval rests on peer review and automation; external boards do not lower
failure. A failed change is dropped from the queue before merge, or reverted or switched off
after. Results come back as tracked items with owners, and the backlog is re-ordered.

**Before merge.** GitHub: required checks "must have a `successful`, `skipped`, or `neutral`
status"; "The branch must be up to date with the base branch before merging." The merge queue
tests each change "applied to the latest version of the target branch". On failure it shows
"the reason why the pull request was removed from the queue" and rebuilds the branches behind it
without the failed change. Software Engineering at Google, ch. 23: presubmit runs "only fast,
reliable ones"; "On post-submit, you can accept longer times and some instability".

**End-to-end and staging.** The Practical Test Pyramid: "reduce the number of end-to-end tests to
a bare minimum." Software Engineering at Google, ch. 14: "Larger tests cover things unit tests
cannot"; they "run post-submit and are also run as part of the release process."

**Canary.** SRE Workbook: canarying is "a partial and time-limited deployment of a change in a
service and its evaluation". "Select the top few metrics ... (perhaps no more than a dozen)." On
failure, "pause and roll back the deployment, or perhaps contact a human". Kayenta: "The judge
compares the canary and baseline metric values"; "The summary score is a weighted average of
group scores". Argo Rollouts: "The failed analysis causes the Rollout to abort". Feature flags let
a change reach "a small percentage of their total userbase" first.

**Approval.** DORA, as in section 3. ITIL's standard, normal and emergency changes: see
`survey-development-flow.md`.

**Removing a failed change.** Software Engineering at Google, ch. 23: "Rolling a change back is
often the fastest and safest route"; "rollbacks give us confidence to undo." LLVM: "Any time you
learn of a serious problem with a change, you should revert it", with "a means for the patch
author to debug the root issue." Chromium's gardener should "Revert changes that you know or
suspect are causing breakages". Google release branches take fixes by cherry-pick. A kill switch
turns a feature off without a redeploy (Feature Toggles).

**Feeding the next cycle.** Postmortems: "All action items have both an owner and a tracking
number"; "Without a formal tracking process, action items from postmortems are often forgotten".
Error budgets: when they run out, "releases are temporarily halted". Scrum Sprint Review: "inspect
the outcome of the Sprint and determine future adaptations"; "The Product Backlog may also be
adjusted". Continuous discovery (Torres): "interview customers continuously—week over week", and
map outcomes to opportunities to solutions. Lean Startup: "validated learning".

**Replacement wording.** Steps 6, 7 and 8 above, and the tracked-item clause in step 1.

## Sources

Prioritisation
- Black Swan Farming, Cost of Delay: https://blackswanfarming.com/cost-of-delay/
- Black Swan Farming, CD3: https://blackswanfarming.com/cost-of-delay-divided-by-duration/
- SAFe WSJF (2016 archive): https://webarchive.library.unt.edu/web/20161225132214mp_/http://www.scaledagileframework.com/wsjf
- SAFe WSJF (current): https://framework.scaledagile.com/wsjf/
- Intercom, RICE: https://www.intercom.com/blog/rice-simple-prioritization-for-product-managers/
- Strategyn, opportunity algorithm: https://strategyn.com/outcome-driven-innovation/market-opportunity/
- Summary of Hubbard, How to Measure Anything: https://www.lesswrong.com/posts/ybYBCK9D7MZCcdArB/how-to-measure-anything
- CodeScene hotspots: https://codescene.io/docs/guides/technical/hotspots.html
- CodeScene, prioritize technical debt: https://codescene.com/blog/prioritize-technical-debt/
- Fowler, Technical Debt: https://martinfowler.com/bliki/TechnicalDebt.html
- Shape Up, appetite: https://basecamp.com/shapeup/1.2-chapter-03
- Linear triage intelligence: https://linear.app/docs/triage-intelligence
- LLM requirements prioritisation: https://arxiv.org/abs/2405.01564

Proposal review
- Design Docs at Google: https://www.industrialempathy.com/posts/design-docs-at-google/
- Uber RFCs: https://blog.pragmaticengineer.com/scaling-engineering-teams-via-writing-things-down-rfcs/
- Rust RFCs: https://github.com/rust-lang/rfcs/blob/master/README.md
- KEP process: https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/0000-kep-process/README.md
- KEP template: https://github.com/kubernetes/enhancements/blob/master/keps/NNNN-kep-template/README.md
- PEP 1: https://peps.python.org/pep-0001/
- Oxide RFD 1: https://rfd.shared.oxide.computer/rfd/0001
- Amazon 2017 letter: https://www.aboutamazon.com/news/company-news/2017-letter-to-shareholders
- Amazon 2016 letter: https://www.aboutamazon.com/news/company-news/2016-letter-to-shareholders
- Amazon 2015 letter: https://www.sec.gov/Archives/edgar/data/1018724/000119312516530910/d168744dex991.htm
- Working Backwards PR/FAQ: https://workingbackwards.com/resources/working-backwards-pr-faq/
- HashiCorp RFC template: https://www.hashicorp.com/how-hashicorp-works/articles/rfc-template
- Nygard, ADRs: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions

Reviewers and separation of duties
- ISTQB independence of testing (mirror): https://istqb-glossary.page/independence-of-testing/
- AWS Well-Architected review process: https://docs.aws.amazon.com/wellarchitected/latest/framework/the-review-process.html
- Google code review standard: https://google.github.io/eng-practices/review/reviewer/standard.html
- Software Engineering at Google, ch. 9: https://abseil.io/resources/swe-book/html/ch09.html
- GitHub CODEOWNERS: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- GitHub protected branches: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- DORA, streamlining change approval: https://dora.dev/capabilities/streamlining-change-approval/
- NIST SP 800-53 AC-5 (mirror): https://csf.tools/reference/nist-sp-800-53/r5/ac/ac-5/
- PCI DSS 6.5.4 (mirror): https://ce.prod.cloudaware.com/frameworks/pci-dss-v4.0/06/05/04
- SLSA source requirements: https://slsa.dev/spec/v1.2/source-requirements
- Claude Code subagents: https://code.claude.com/docs/en/sub-agents
- Claude Code code review: https://code.claude.com/docs/en/code-review
- Claude Code GitHub Actions: https://code.claude.com/docs/en/github-actions
- Claude Code security review: https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code
- Codex GitHub integration: https://learn.chatgpt.com/docs/third-party/github
- Copilot code review: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review
- Copilot coding agent PRs: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/review-copilot-prs
- MetaGPT: https://arxiv.org/abs/2308.00352
- ChatDev: https://arxiv.org/abs/2307.07924

Running the system
- ISTQB terms (v3.1, quoted in): https://arxiv.org/pdf/1802.03768
- Kaner, exploratory testing: https://kaner.com/?p=46
- Bach, Exploratory Testing Explained: https://www.cs.uleth.ca/~benkoczi/3720/pres/exploratory_testing_explainedBach03.pdf
- Session-based test management: https://www.satisfice.com/download/session-based-test-management
- Dogfooding: https://en.wikipedia.org/wiki/Eating_your_own_dog_food
- OSS-Fuzz: https://google.github.io/oss-fuzz/
- ClusterFuzz: https://google.github.io/clusterfuzz/
- libFuzzer: https://llvm.org/docs/LibFuzzer.html
- AFL: https://github.com/google/AFL
- AI-powered fuzzing (2023): https://security.googleblog.com/2023/08/ai-powered-fuzzing-breaking-bug-hunting.html
- AI-powered fuzzing (2024): https://security.googleblog.com/2024/11/leveling-up-fuzzing-finding-more.html
- QuickCheck: https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf
- Hypothesis: https://hypothesis.readthedocs.io/en/latest/
- Android Monkey: https://developer.android.com/studio/test/other-testing-tools/monkey
- Chaos Monkey: https://netflix.github.io/chaosmonkey/
- Principles of Chaos Engineering: https://principlesofchaos.org/
- Predictive test selection: https://arxiv.org/abs/1810.05286
- GraphWalker: https://graphwalker.github.io/
- τ-bench: https://arxiv.org/abs/2406.12045
- Anthropic, Demystifying evals for AI agents: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- Barr et al., The Oracle Problem in Software Testing (IEEE TSE 2015): https://doi.org/10.1109/TSE.2014.2372785

Verify, validate, release
- GitHub merge queue: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue
- Software Engineering at Google, ch. 23: https://abseil.io/resources/swe-book/html/ch23.html
- Software Engineering at Google, ch. 14: https://abseil.io/resources/swe-book/html/ch14.html
- Trunk-based development: https://trunkbaseddevelopment.com/
- The Practical Test Pyramid: https://martinfowler.com/articles/practical-test-pyramid.html
- SRE Workbook, Canarying Releases: https://sre.google/workbook/canarying-releases/
- Argo Rollouts analysis: https://argoproj.github.io/argo-rollouts/features/analysis/
- Spinnaker canary judge: https://spinnaker.io/docs/guides/user/canary/judge/
- Feature Toggles: https://martinfowler.com/articles/feature-toggles.html
- SRE book, Release Engineering: https://sre.google/sre-book/release-engineering/
- LLVM developer policy: https://llvm.org/docs/DeveloperPolicy.html
- Chromium gardener: https://chromium.googlesource.com/chromium/src/+/HEAD/docs/gardener.md
- SRE book, Embracing Risk: https://sre.google/sre-book/embracing-risk/
- SRE Workbook, Postmortem Culture: https://sre.google/workbook/postmortem-culture/
- Scrum Guide 2020: https://scrumguides.org/scrum-guide.html
- Opportunity solution trees: https://www.producttalk.org/opportunity-solution-trees/
- Lean Startup principles: https://theleanstartup.com/principles

## Metadata

- Written 2026-10-10 to replace the details of section 2.2 that came from notes meant only to
  say what to survey.
- Quotes were taken through a fetch tool that summarises pages. They were not checked character
  by character against the raw pages.
- Not verified at a primary source: ISTQB glossary wording (secondary copies), ISTQB levels of
  independence, ICE, McConnell's cone, ITIL 4 change authority, TOGAF Architecture Board, Google
  TAP, Google's dogfood stage, Reinertsen's page number.
- Marked *ours* in the body: one user simulator as the only driver of M.f; an AI planner running
  the prioritisation; in-iteration data; Elevate.
