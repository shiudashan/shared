// Tests of sync and upstream on temporary git repositories:
//   origin.git   a bare repository standing for shared on GitHub
//   shared/      a working clone of it, where shared's S/ is edited
//   project/     a project with origin.git as the submodule `shared`, and a generation g1/

import { afterAll, afterEach, beforeEach, expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { git, listDir } from "../src/git";
import { sync } from "../src/sync";
import { upstream } from "../src/upstream";

// A git configuration of the tests' own, so the submodule may clone from a local path.
const gitConfig = join(realpathSync(mkdtempSync(join(tmpdir(), "s-test-config-"))), "gitconfig");
writeFileSync(gitConfig, "[protocol \"file\"]\n\tallow = always\n[init]\n\tdefaultBranch = main\n[user]\n\tname = test\n\temail = test@example.com\n");
Object.assign(process.env, { GIT_CONFIG_GLOBAL: gitConfig, GIT_CONFIG_NOSYSTEM: "1" });

let root: string;
let origin: string;
let shared: string;
let project: string;
let gen: string;

const lines = (...xs: string[]) => xs.map((x) => `${x}\n`).join("");
const put = (path: string, text: string) => {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text);
};
const read = (path: string) => readFileSync(path, "utf8");
const commitAll = (repo: string, msg: string) => {
  git(repo, "add", "-A");
  git(repo, "commit", "-m", msg);
};
/** Content hashes of every file under dir, .git excluded. */
const snapshot = (dir: string) =>
  Object.fromEntries(listDir(dir).map((p) => [p, createHash("sha1").update(readFileSync(join(dir, p))).digest("hex")]));

const METHOD = lines("# Method", "one", "two", "three", "four", "five", "six", "seven");

beforeEach(() => {
  root = realpathSync(mkdtempSync(join(tmpdir(), "s-test-")));
  origin = join(root, "origin.git");
  shared = join(root, "shared");
  project = join(root, "project");
  gen = join(project, "g1");
  git(root, "init", "--bare", origin);
  git(root, "clone", origin, shared);
  put(join(shared, "S/method.md"), METHOD);
  put(join(shared, "S/prompts/planner.txt"), lines("plan well"));
  commitAll(shared, "S");
  git(shared, "push", "origin", "main");

  mkdirSync(project);
  git(project, "init");
  git(project, "submodule", "add", origin, "shared");
  put(join(gen, "spec.md"), lines("g1 spec"));
  commitAll(project, "project");
});

afterEach(() => rmSync(root, { recursive: true, force: true }));
afterAll(() => rmSync(dirname(gitConfig), { recursive: true, force: true }));

test("first sync copies the layer above and records BASE", () => {
  const r = sync(project);
  expect(r.from).toBeNull();
  expect(r.added.sort()).toEqual(["method.md", "prompts/planner.txt"]);
  expect(read(join(project, "S/method.md"))).toBe(METHOD);
  expect(read(join(project, "S/BASE")).trim()).toBe(git(shared, "rev-parse", "HEAD"));

  commitAll(project, "sync");
  const g = sync(gen);
  expect(g.added.sort()).toEqual(["method.md", "prompts/planner.txt"]);
  expect(read(join(gen, "S/BASE")).trim()).toBe(git(project, "rev-parse", "HEAD"));
});

test("a later sync merges a change above and keeps this layer's customisation", () => {
  sync(project);
  put(join(project, "S/method.md"), METHOD.replace("six", "six, as this project does it"));
  put(join(project, "S/local.md"), lines("the project's own file"));
  commitAll(project, "customise");

  put(join(shared, "S/method.md"), METHOD.replace("one", "one, improved"));
  put(join(shared, "S/reviewers.md"), lines("# Reviewers"));
  commitAll(shared, "improve");
  git(shared, "push", "origin", "main");

  const r = sync(project);
  expect(r.merged).toEqual(["method.md"]);
  expect(r.added).toEqual(["reviewers.md"]);
  expect(r.conflicts).toEqual([]);
  const m = read(join(project, "S/method.md"));
  expect(m).toContain("one, improved");
  expect(m).toContain("six, as this project does it");
  expect(read(join(project, "S/local.md"))).toContain("the project's own file");
  expect(read(join(project, "S/BASE")).trim()).toBe(git(shared, "rev-parse", "HEAD"));
});

test("a conflicting change leaves markers and is reported", () => {
  sync(project);
  put(join(project, "S/method.md"), METHOD.replace("three", "three, the project's way"));
  commitAll(project, "customise");
  put(join(shared, "S/method.md"), METHOD.replace("three", "three, shared's way"));
  commitAll(shared, "change");
  git(shared, "push", "origin", "main");

  const r = sync(project);
  expect(r.conflicts).toEqual(["method.md"]);
  const m = read(join(project, "S/method.md"));
  expect(m).toContain("<<<<<<<");
  expect(m).toContain("three, the project's way");
  expect(m).toContain("three, shared's way");
});

test("upstream from a generation applies only the named files, and commits them in the project", () => {
  sync(project);
  commitAll(project, "sync shared");
  sync(gen);
  commitAll(project, "sync g1");

  put(join(gen, "S/method.md"), METHOD.replace("two", "two, learned in g1"));
  put(join(gen, "S/prompts/planner.txt"), lines("plan well, for g1 only"));
  commitAll(project, "g1 edits");
  // An unrelated change above since BASE, which upstream must keep.
  put(join(project, "S/method.md"), METHOD.replace("seven", "seven, the project's"));
  commitAll(project, "project edit");

  const before = git(project, "rev-parse", "HEAD");
  const r = upstream(gen, ["S/method.md"]);
  expect(r.applied).toEqual(["method.md"]);
  expect(r.conflicts).toEqual([]);
  const m = read(join(project, "S/method.md"));
  expect(m).toContain("two, learned in g1");
  expect(m).toContain("seven, the project's");
  expect(read(join(project, "S/prompts/planner.txt"))).toBe(lines("plan well"));
  expect(git(project, "diff", "--name-only", before, "HEAD")).toBe("S/method.md");
  expect(git(project, "status", "--porcelain")).toBe("");
});

test("upstream never writes to the layer it carries from", () => {
  sync(project);
  commitAll(project, "sync shared");
  sync(gen);
  put(join(gen, "S/method.md"), METHOD.replace("two", "two, learned in g1"));
  commitAll(project, "g1");

  const genBefore = snapshot(gen);
  upstream(gen, ["method.md"]);
  expect(snapshot(gen)).toEqual(genBefore);

  // Project to shared: a branch and a pull request in shared; the project stays as it was.
  put(join(project, "S/method.md"), read(join(project, "S/method.md")).replace("four", "four, worth sharing"));
  commitAll(project, "project edit");
  const projectBefore = snapshot(project);
  const submoduleBefore = git(join(project, "shared"), "rev-parse", "HEAD");
  const prs: string[] = [];
  const r = upstream(project, ["method.md"], {
    branch: "upstream/test",
    openPr: ({ head, title }) => {
      prs.push(`${head}: ${title}`);
      return "https://example.com/pr/1";
    },
  });
  expect(r.applied).toEqual(["method.md"]);
  expect(prs).toEqual(["upstream/test: S: upstream method.md from project"]);
  expect(snapshot(project)).toEqual(projectBefore);
  expect(git(join(project, "shared"), "rev-parse", "HEAD")).toBe(submoduleBefore);
  expect(git(project, "status", "--porcelain")).toBe("");
  // The branch reached the remote; shared's main did not move.
  const onBranch = git(origin, "show", "upstream/test:S/method.md");
  expect(onBranch).toContain("four, worth sharing");
  expect(onBranch).toContain("two, learned in g1");
  expect(git(origin, "rev-parse", "main")).toBe(submoduleBefore);
});
