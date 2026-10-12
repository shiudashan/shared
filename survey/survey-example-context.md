# Survey: how much project context an upstreamed example keeps

Survey date: 2026-10-12.

This survey covers one question. When a finding, a review, a decision or a use case moves up a
layer, how much of its project's context should it carry? It does not repeat
`survey-data-curation.md` (collection, de-duplication, the curation pipeline) or
`survey-upstreaming.md` (who moves a change up, and the five acts).

"Inference" marks a step that is ours and not taken from a source.

## Answer: the form of an upstreamed example

Six fields of practice agree on one shape. An example is the smallest thing that still shows
its point, plus just the context a stranger needs to read it. Every field tests both halves
from the reader's side, not the writer's.

The form has three parts.

**1. Keep, verbatim: the evidence and the verdict.**
- Keep the lines the judgement rests on, as they were written: log lines, diff hunks, the grade
  and its reason. Developers rank steps to reproduce and stack traces as the most useful parts
  of a bug report (Bettenburg, Zimmermann et al.). Demonstrations teach a model mainly through
  their format and the look of their inputs (Min et al. 2022). A paraphrased symptom loses both.
- Keep the numbers and their units. They let the reader judge scale.
- Check: the verdict still follows from what is kept. This is the "interestingness test" of
  test-case reduction (Zeller; Regehr et al.). For S, the test is a reader in a fresh context:
  a model that gets only the example, with no access to the project, and makes the same
  judgement as the example's verdict. Inference: the fresh-context reader as S's
  interestingness test is ours.

**2. Inject: only what a stranger needs to interpret what is kept.**
- Replace each name that only the lower layer understands with what it denotes: ids of use
  cases, runs and proposals; generation names; project jargon. These are the edits of
  decontextualization: name completion, pronoun and noun-phrase swap, bridging (adding a
  modifier to a noun), global scoping (adding a phrase for the whole sentence), and removal of
  discourse markers (Choi et al. 2021).
- State the environment in one or two sentences: what kind of system, what the run was trying
  to do. This is the KCS "Environment" field, which must be "precise" because it separates one
  article from another with the same symptom.
- State the reference the evidence is judged against, inline, not by id.
- Add only what removes an ambiguity, and nothing that merely helps. Molecular facts (Gunjal and
  Durrett 2024) define the target as stand-alone "while adding as little information as
  possible to do so". In their data, simple decontextualization over-added in up to 9.6% of
  cases.
- A short situating sentence of 50 to 100 tokens is what contextual retrieval prepends to each
  chunk (Anthropic 2024).
- Check: generate the questions a stranger would ask of the example (Newman et al. 2023). Each
  question that bears on the verdict must be answered inside the example. Questions that do not
  bear on the verdict need no answer.

**3. Drop: everything whose removal leaves the verdict unchanged.**
- Remove one unit at a time: a symptom line, a sentence, a diff hunk, a span of a trace. If the
  fresh-context reader still makes the same judgement, the unit goes. The result is
  "1-minimal": no single unit can be removed without losing the point (Zeller and Hildebrandt
  2002).
- Remove large units before small ones. Hierarchical delta debugging removes whole subtrees
  first, and keeps the structure valid (Misherghi and Su 2006). For S, the levels are the
  entry, its fields, and the lines inside a field. (Inference.)
- Do not paste long sources. Abstract them, and link the unedited original in the lower layer.
  This is how Google SRE's model postmortem handles chat transcripts and logs.
- Drop most of all the details that look relevant but are not. Distractors that share words,
  names or number ranges with the problem hurt models most (Shi et al. 2023).
- Check: the size budget. Inference, from the sources: one example of a few hundred tokens,
  with its evidence at most a few dozen lines. SSCCE puts reader fatigue at 100 lines of code.
  Anthropic's retrieval chunks are "usually no more than a few hundred tokens". Anthropic's
  prompting guide recommends 3 to 5 examples, so the budget is per example times five. A
  measured drop in a reviewer's agreement when examples grow would prove this budget wrong.

**When the balance cannot be struck.** About 10% of sentences could not be made to stand alone
without changing their meaning (Choi et al. 2021). Inference: an entry that fails the
fresh-reader check after injection stays in its layer. It is not forced up.

**How S automates it.** Inference, from section 2. A model proposes the reductions and the
context edits. The fresh-reader check accepts or rejects each one, in a delta-debugging loop.
Pure LLM reduction is unreliable: a one-shot LLM reducer succeeded on 40% of bugs, against a
hybrid that generates a reducer and checks it (ReduceFix 2025). Cost, from the cost model in
`survey-data-curation.md` (about 6 s per judgement): a symptom of 10 lines takes some 10 to 40
checks, so one to four minutes per entry.

### The two legs

The form is the same on both legs. What counts as "context only the lower layer understands"
differs. (Inference, applying the form.)

- **Iteration to project.** The project still holds the domain. What must be injected or
  replaced is iteration-specific: generation names, iteration file paths, ids of items and runs
  that do not survive the iteration, names of temporary settings. Little is dropped. The
  domain words stay.
- **Project to shared.** The domain is gone. Domain terms become general terms, as a design
  pattern states a problem without a particular system. The environment sentence becomes the
  pattern's context: when the example applies. Evidence stays verbatim where possible. Where
  the domain cannot be removed from the evidence, the evidence is replaced by a made-up minimal
  instance that still passes the fresh-reader check, marked `made_up: true`.

The two made-up run reviews already in `S/data/run-reviews/` meet this form. Each finding names
the specific fault and then the general rule. Each symptom is verbatim log lines, and every
line bears on the verdict.

### Per data type

Each line gives what to keep, inject and drop, and the check. All are inferences applying the
form above to the fields in `S/specs/data.md`.

- **Run reviews.** Keep: `finding`, `severity`, and the `symptom` lines the finding rests on.
  Inject: the `reference` stated in words; the environment in one sentence. Drop: symptom lines
  the finding does not need. Leg 2: domain words in `finding` become general; the general rule
  in the finding's last sentence is the pattern. Check: a fresh reviewer given the symptom and
  environment writes a finding of the same kind and severity.
- **Run grades.** Keep: `grade`, `reason`. Inject: the rubric checks the reason refers to, and
  the slice of the run it judged. Drop: the rest of the run. Check: a fresh grader given the
  slice and the rubric gives the same grade, within a tolerance fixed beforehand.
- **Run records.** Do not go up whole. They are the long source that is abstracted and linked.
  Slices of them go up inside run reviews and grades, as evidence.
- **Use cases.** Keep: `seed`, `reference`, `rubric`. Inject: what M is, in one sentence, so
  the rubric's checks make sense. Leg 2: as a format example only. Check: a fresh grader scores
  the `reference` near 1 against the rubric, and scores a deliberately broken answer lower.
- **Proposals.** Leg 1: keep whole, replace ids with what they denote. Leg 2: the pattern form
  of section 6. Context: the generalised finding. Problem and solution: `gain`, `delta`,
  `design`. Consequences: `upsides` and `downsides`, amounts kept with their units and the
  scale they were measured at. Drop: `tasks`, `rank`, `changed`; they mean nothing outside the
  project's order. Check: a reviewer from another project can say whether the proposal applies
  to its own situation, from the context field alone.
- **Proposal reviews.** Travel with their proposal. Keep each correction's `from`, `to` and
  `reason`. Check: a stranger can see why the correction was right from the proposal and the
  review together.
- **Decisions.** A bare `approve` with ids is meaningless one layer up, because the ids do not
  resolve there. Keep: `decision`, `reason`. Inject: a short statement of what was decided,
  with the gain and the main downside of the proposal. Check: a fresh decision maker given only
  the entry makes the same decision, and the reason refers only to things inside the entry.
- **Code reviews.** Keep: the comment's `text` and `rule`. Inject: the language and framework.
  Reduce the diff to the smallest hunk that still draws the comment, keeping it valid code, as
  C-Reduce keeps a program compiling. Leg 2: project code is withheld, so the hunk becomes a
  made-up minimal snippet. Check: the code reviewer, given the reduced hunk, raises the same
  rule.

## 1. The minimal reproducible example

**Stack Overflow, "How to create a Minimal, Reproducible Example".**
https://stackoverflow.com/help/minimal-reproducible-example. (The page could not be fetched
directly for this survey. The content below is from mirrors and the search index.) Three rules:
minimal, as little code as possible that still produces the same problem; complete, everything
someone else needs to reproduce it, in the question itself; reproducible, tested to show the
problem. Two ways to get there: start from scratch and add only what is needed, or divide and
conquer, removing code until the problem disappears and then putting the last piece back. The
page warns not to sacrifice clarity for brevity.

**SSCCE.** http://sscce.org/. "Short (Small) - Minimise bandwidth for the example, do not bore
the audience." "Self Contained - Ensure everything is included, ready to go." "Correct" means
"Copy, paste, (compile,) see is the aim." "Example - Displays the problem we are trying to
solve." On size: "most readers will stop reading by 100 lines of code, and start complaining at
250-300 lines of code." Before posting, confirm the problem still appears in the reduced code.

**reprex (R).** https://reprex.tidyverse.org/articles/reprex-dos-and-donts.html. "Use the
smallest, simplest, most built-in data possible." "Include commands on a strict 'need to run'
basis." "Ruthlessly strip out anything unrelated to the specific matter at hand." Include
session info when versions might matter. Leave out hard-coded paths from your own machine.
The package runs the example in a fresh session, so a missing piece shows up as an error.

**Bug-report quality.** Bettenburg, Just, Schröter, Weiss, Premraj, Zimmermann, "What Makes a
Good Bug Report?", FSE 2008. https://www.st.cs.uni-saarland.de/softevo/bugreports.php. A survey
of Apache, Eclipse and Mozilla developers (466 responses in the FSE version). Steps to
reproduce, stack traces and test cases are the most helpful parts, and the hardest for
reporters to supply. Inaccurate steps and incomplete information are the largest hurdles. There
is a mismatch between what developers need and what reporters give. Their tool CUEZILLA rates a
new report and recommends the missing elements.

**For S.** "Complete" is the inject half; "minimal" is the drop half; "reproducible" is the
check. reprex's fresh session is the model for S's fresh-context reader. The mismatch finding
says the check must be done from the reader's side. CUEZILLA is the model for a checker that
names what an entry lacks. (Inference.)

**Check.** The fresh-context reader reproduces the verdict. Removing any one unit loses it.

## 2. Test-case reduction

**Delta debugging.** Zeller and Hildebrandt, "Simplifying and Isolating Failure-Inducing
Input", IEEE TSE 28(2), 2002. https://www.st.cs.uni-saarland.de/papers/tse2002/. The ddmin
algorithm splits the input into blocks, tests each block and each complement, and refines the
split until the result is 1-minimal: removing any single unit makes the failure disappear. It
reduced 95 user actions crashing Mozilla to 3, and 896 lines of HTML to one. The unit can be a
character, a line, or anything atomic for the input.

**Hierarchical delta debugging.** Misherghi and Su, "HDD: Hierarchical Delta Debugging", ICSE
2006. https://www.cs.ucdavis.edu/~su/publications/icse06-hdd.pdf. Runs ddmin level by level on
a tree, coarsest first. Removing a node removes its subtree. Plain ddmin does poorly on inputs
with mandatory structure; HDD keeps the structure.

**C-Reduce and C-Vise.** Regehr, Chen, Cuoq, Eide, Ellison, Yang, "Test-Case Reduction for C
Compiler Bugs", PLDI 2012. https://www-old.cs.utah.edu/~regehr/papers/pldi12-preprint.pdf.
Domain-specific transformations give outputs on average over 25 times smaller than other
reducers. The user writes an interestingness test, a script whose exit code says whether a
variant still shows the bug. Regehr warns that it is easy to write a test that finds the empty
file interesting (https://blog.regehr.org/archives/1678). C-Vise
(https://github.com/marxin/cvise) is a parallel Python port, compatible with C-Reduce, and also
works on other languages.

**LLM-based reduction.** LPR (Zhang et al., arXiv 2312.13064,
https://arxiv.org/abs/2312.13064) combines a generic syntax-level reducer with
language-specific transformations proposed by an LLM. On 50 benchmarks it produced programs
24.93%, 4.47% and 11.71% smaller than Vulcan on C, Rust and JavaScript. ReduceFix (arXiv
2507.15251, https://arxiv.org/abs/2507.15251) has an LLM write a reducer for failing inputs,
shrinking them by 89.1% on average. A one-shot pure-LLM baseline succeeded on only 40% of bugs.
The pattern across these papers: the LLM proposes, a mechanical check decides.

**For S.** The interestingness test is the whole method. S's version is the fresh-context
reader making the same judgement. The empty-file trap has an S form: a check that only asks "is
this a reasonable finding?" accepts an example stripped of its evidence. The check must ask
for the same verdict, from the evidence given. Units for S: entries, then fields, then lines
(HDD's levels). (Inference.)

**Check.** Each accepted reduction keeps the verdict. The empty example fails the check; run it
once to prove the check is not vacuous. (Inference.)

## 3. Decontextualization

**Choi et al. 2021.** "Decontextualization: Making Sentences Stand-Alone", TACL 9.
https://aclanthology.org/2021.tacl-1.27. A rewrite s′ of sentence s must meet two conditions:
"the sentence s′ is interpretable in the empty context", and its "truth-conditional meaning ...
in the empty context is the same as" that of s in its context. The edit types: pronoun or
noun-phrase swap; name completion ("Expansion of acronyms or partial names"); removal of
discourse markers "that can be only understood in context"; bridging ("Addition of a modifier
(typically a PP) to a noun phrase"); global scoping; and addition of background that "is not
necessary but helps readability significantly". About 10% of sentences were infeasible. Raters
showed "a statistically significant preference for decontextualized sentences" as answers.
For retrieval, decontextualized sentences came near 100-word windows "with 1/10th the cost".

**Molecular facts.** Gunjal and Durrett, Findings of EMNLP 2024.
https://arxiv.org/abs/2406.20079. Two criteria: decontextuality, and minimality ("Adding too
much information to a claim makes it less minimal"). Their method first asks what in the claim
is ambiguous, then adds only the context that resolves it. Simple decontextualization added
non-minimal content in 1.7% to 9.6% of cases.

**Scientific snippets.** Newman, Soldaini, Fok, Cohan, Lo, EMNLP 2023.
https://aclanthology.org/2023.emnlp-main.193. Three stages: generate the questions a reader
would ask of the snippet, answer them from the source document, rewrite with the answers.
Rewriting was easy for models; asking the right questions and answering them were hard.

**For S.** The edit types are the inject half, named. The minimality criterion is the brake on
it. Newman's questions are the operational check. The 10% infeasible rate says some entries
should stay in their layer. (Inference.)

**Check.** List the stranger's questions. Every question bearing on the verdict is answered in
the entry. No added sentence answers a question that does not bear on it.

## 4. Contextual retrieval and the retrieval unit

**Contextual retrieval.** Anthropic, September 2024.
https://www.anthropic.com/news/contextual-retrieval. A model is given the whole document and
the chunk, with the prompt "Please give a short succinct context to situate this chunk within
the overall document". The context, "usually 50-100 tokens", is prepended before embedding and
BM25 indexing. Retrieval failures in the top 20 fell 35% with contextual embeddings, 49% adding
contextual BM25, and 67% adding reranking. Chunks are "usually no more than a few hundred
tokens". Below about 200,000 tokens, the post suggests putting the whole knowledge base in the
prompt instead.

**Late chunking.** Günther et al., Jina AI, arXiv 2409.04701.
https://arxiv.org/abs/2409.04701. Embed the whole document with a long-context model, then
split into chunks just before pooling, so each chunk's vector carries its neighbours' context.
No LLM call per chunk.

**Propositions as the unit.** Chen et al., "Dense X Retrieval", EMNLP 2024.
https://arxiv.org/abs/2312.06648. A proposition is a distinct piece of meaning, minimal, and
"contextualized and self-contained" (citing Choi et al.). Indexing by propositions beat
passages and sentences, and helped downstream QA at a fixed token budget.

**For S.** The best unit is small and self-contained, with a short situating context: the same
form as section 3. At S's size, tens to hundreds of entries per layer, the whole of `shared`'s
data may fit under the 200,000-token line, so findability matters less than reading cost.
The budget is then set by in-context use, section 5. Late chunking does not apply: S's entries
are written as separate units, not cut from a document. (Inference.)

**Check.** The entry's first sentence alone tells a reader which situation it is about.

## 5. Example length and self-containedness in context

**Distraction.** Shi et al., "Large Language Models Can Be Easily Distracted by Irrelevant
Context", ICML 2023. https://arxiv.org/abs/2302.00093. On GSM-IC, adding one irrelevant
sentence left "fewer than 30% of the base problems ... consistently solved". Distractors that
are in topic, share role names, or have numbers in range hurt most. Two mitigations: the
instruction "Feel free to ignore irrelevant information given in the questions", and
"using exemplars with distractors consistently outperforms using the original exemplars".

**Position and length.** Liu et al., "Lost in the Middle", TACL 2024.
https://aclanthology.org/2024.tacl-1.9. Accuracy is highest when the relevant information sits
at the start or end of the context, and drops in the middle. Chroma's "Context Rot" report
(Hong, Troynikov, Huber, July 2025, https://www.trychroma.com/research/context-rot) found
performance falling with input length across 18 models, even on simple tasks.

**What demonstrations teach.** Min et al., "Rethinking the Role of Demonstrations", EMNLP 2022.
https://arxiv.org/abs/2202.12837. Random labels barely hurt. Demonstrations work through the
label space, the distribution of the input text, and the format. Agarwal et al., "Many-Shot
In-Context Learning", NeurIPS 2024 (https://arxiv.org/abs/2404.11018): with hundreds of
examples, model-written rationales and even inputs without answers can match human-written
solutions.

**Prompting guidance.** Anthropic's prompting best practices
(https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices):
examples should be "Relevant", "Diverse" and "Structured", wrapped in `<example>` tags; "Include
3–5 examples for best results."

**Summarise or keep verbatim.** LLMLingua (Jiang et al., EMNLP 2023,
https://aclanthology.org/2023.emnlp-main.825) compressed prompts up to 20 times with a
1.5-point loss on GSM8K and BBH. Third-party review notes that random sentence selection beat
the methods in some cases at 2 times. Google SRE abstracts long logs and links the originals
(section 6).

**LLM judges.** In MT-Bench (Zheng et al. 2023, https://arxiv.org/abs/2306.05685), few-shot
examples raised GPT-4's consistency from 65.0% to 77.5%, but agreement with humans stayed about
the same as zero-shot. I found no controlled study of how long a judge's examples should be.

**For S.** Three consequences. (Inference.)
- Keep the evidence in the form the reviewer will meet in real runs (Min et al.): verbatim log
  lines, not a summary of them. Summarise the surrounding context, not the evidence.
- Drop the look-alike details first (Shi et al.): project names and numbers that resemble the
  evidence but do not bear on it.
- Shi et al.'s second finding cuts the other way. If real run records are noisy, an example set
  where some examples carry one or two irrelevant lines may teach the reviewer to ignore noise.
  I am not sure this transfers to S. It would show up as a measured gain in agreement with the
  person when such examples are added.

**Check.** The reviewer's agreement with the person (Cohen's kappa, already S's measure) does
not drop when an example is shortened, and does not rise when it is lengthened. If it rises,
the shortened form dropped something needed.

## 6. Generalising examples across projects

**Pattern form.** Alexander, *A Pattern Language*, 1977
(https://en.wikipedia.org/wiki/Pattern_language). Each pattern states the context it applies
in, the problem, and the solution, introduced by "therefore", and links to the larger and
smaller patterns around it. Alexander rates each pattern by stars for how well it is proven.
Gamma, Helm, Johnson, Vlissides, *Design Patterns*, 1994
(https://en.wikipedia.org/wiki/Design_Patterns): four essential elements, the name, the
problem (with its context: when to apply the pattern), the solution (abstract, not a particular
design), and the consequences (results and trade-offs). The book pairs each abstract solution
with sample code and "known uses": the general statement plus concrete instances.

**Postmortems shared across teams.** Google SRE Workbook, chapter 10.
https://sre.google/workbook/postmortem-culture/. Its bad example "introduces terminology that's
specific to traffic serving" with empty Background and Glossary sections. "If you don't
properly contextualize content when writing a postmortem, the document might be misunderstood
or even ignored." "Your audience extends beyond the immediate team." In the good example,
"Lengthy data sources, such as chat transcripts and system logs, were abstracted, with the
unedited versions linked from the main document", and it "strikes a balance between verbosity
and readability". Sharing: postmortem of the month, reading clubs, cross-team reviews.

**Lessons-learned databases.** NASA LLIS. https://www.nasa.gov/nasa-lessons-learned/. Each
lesson has "a summary of the original driving event and recommendations"; entries also carry
an abstract and evidence of recurrence control (NASA technical paper,
https://ntrs.nasa.gov/api/citations/20120017921/downloads/20120017921.pdf). NASA's Inspector
General found that program and project managers rarely consult or contribute to LLIS
(IG-12-012, https://www.oversight.gov/sites/default/files/oig-reports/IG-12-012.pdf). A store
of lessons that is not read in the flow of work goes unused.

**Knowledge-base articles.** KCS v6 Practices Guide, Technique 2.1.
https://library.serviceinnovation.org/KCS/KCS_v6/KCS_v6_Practices_Guide/030/030/020/010. An
article has an Issue, "the situation in the requestor's words"; an Environment, which "should
be precise"; a Resolution; an optional Cause, "typically only valuable for complex problems";
and Metadata. "Relevant environment statements are critical": they separate an article from
others with similar symptoms and a different resolution. After resolution, refine the
environment statements "to be sure they are relevant". Start with one simple template.

**For S.** Each field keeps context in a named slot, apart from the general point: Alexander's
and the GoF's context, the postmortem's background and glossary, NASA's driving event, KCS's
environment. The slot holds exactly what decides whether the example applies. The general
point keeps one concrete instance (GoF's sample code, the postmortem's linked logs). The
upstreamed run review's last sentence is the solution; its symptom is the instance. The NASA
audit says the examples must be read where the work happens: inside the reviewers' prompts,
not only in a folder. Alexander's stars correspond to the occurrence count that
`survey-data-curation.md` already keeps. (Inference.)

**Check.** A reader from another project, given only the context slot, can say whether the
example applies to its own situation. A KCS-style check: two entries with the same symptom and
different verdicts must differ in their environment sentence.

## Sources

- Stack Overflow, How to create a Minimal, Reproducible Example:
  https://stackoverflow.com/help/minimal-reproducible-example
- SSCCE: http://sscce.org/
- reprex dos and don'ts: https://reprex.tidyverse.org/articles/reprex-dos-and-donts.html
- Bettenburg et al., What Makes a Good Bug Report?:
  https://www.st.cs.uni-saarland.de/softevo/bugreports.php
- Zeller and Hildebrandt 2002: https://www.st.cs.uni-saarland.de/papers/tse2002/
- Misherghi and Su 2006: https://www.cs.ucdavis.edu/~su/publications/icse06-hdd.pdf
- Regehr et al. 2012: https://www-old.cs.utah.edu/~regehr/papers/pldi12-preprint.pdf
- Regehr, Design and Evolution of C-Reduce: https://blog.regehr.org/archives/1678
- C-Vise: https://github.com/marxin/cvise
- LPR: https://arxiv.org/abs/2312.13064
- ReduceFix: https://arxiv.org/abs/2507.15251
- Choi et al. 2021: https://aclanthology.org/2021.tacl-1.27
- Gunjal and Durrett 2024: https://arxiv.org/abs/2406.20079
- Newman et al. 2023: https://aclanthology.org/2023.emnlp-main.193
- Anthropic, Contextual Retrieval: https://www.anthropic.com/news/contextual-retrieval
- Günther et al., Late Chunking: https://arxiv.org/abs/2409.04701
- Chen et al., Dense X Retrieval: https://arxiv.org/abs/2312.06648
- Shi et al. 2023: https://arxiv.org/abs/2302.00093
- Liu et al., Lost in the Middle: https://aclanthology.org/2024.tacl-1.9
- Chroma, Context Rot: https://www.trychroma.com/research/context-rot
- Min et al. 2022: https://arxiv.org/abs/2202.12837
- Agarwal et al. 2024: https://arxiv.org/abs/2404.11018
- Anthropic, Prompting best practices:
  https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Jiang et al., LLMLingua: https://aclanthology.org/2023.emnlp-main.825
- Zheng et al., MT-Bench: https://arxiv.org/abs/2306.05685
- Pattern language: https://en.wikipedia.org/wiki/Pattern_language
- Design Patterns: https://en.wikipedia.org/wiki/Design_Patterns
- Google SRE Workbook, Postmortem Culture: https://sre.google/workbook/postmortem-culture/
- NASA Lessons Learned: https://www.nasa.gov/nasa-lessons-learned/
- NASA technical paper on LLIS:
  https://ntrs.nasa.gov/api/citations/20120017921/downloads/20120017921.pdf
- NASA OIG, IG-12-012: https://www.oversight.gov/sites/default/files/oig-reports/IG-12-012.pdf
- KCS v6 Practices Guide, Technique 2.1:
  https://library.serviceinnovation.org/KCS/KCS_v6/KCS_v6_Practices_Guide/030/030/020/010
