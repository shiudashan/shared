// upstream <layer-dir> <file>...: carries the named edits from a layer's S/ up to the layer
// above's S/. The workflow is specified in ../workflows/upstream.md.

import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join } from "node:path";
import { git, merge3, readAt, readFile, run, same } from "./git";
import { BASE, describe, layerOf, readBase, type Layer } from "./layer";

export type OpenPr = (args: { cwd: string; base: string; head: string; title: string; body: string }) => string;

export type UpstreamOptions = {
  /** Opens the pull request for project to shared. Defaults to `gh pr create`. */
  openPr?: OpenPr;
  /** The branch of shared that pull requests target. */
  mainBranch?: string;
  /** Overrides the name of the branch written in shared. */
  branch?: string;
};

export type UpstreamReport = {
  layer: Layer;
  base: string;
  applied: string[];
  unchanged: string[];
  conflicts: string[];
  /** The commit made in the project, for generation to project. */
  commit?: string;
  /** The branch and pull request, for project to shared. */
  branch?: string;
  pr?: string;
  /** Where the conflicted files were left. */
  conflictDir?: string;
};

const ghPr: OpenPr = ({ cwd, base, head, title, body }) => {
  const r = run(["gh", "pr", "create", "--base", base, "--head", head, "--title", title, "--body", body], cwd);
  if (r.code !== 0) throw new Error(`gh pr create failed: ${r.stderr.trim()}`);
  return r.stdout.toString().trim();
};

/** "S/a.md" and "a.md" both name the file a.md in the layer's S/. */
function normalise(file: string): string {
  const rel = file.replace(/^\.\//, "").replace(/^S\//, "");
  if (!rel || rel === BASE || rel.startsWith("../") || rel.startsWith("/"))
    throw new Error(`not a file of the layer's S/: ${file}`);
  return rel;
}

/**
 * Applies each file's change since BASE onto the layer above's S/, checked out at `upperS`.
 * Never writes into the layer itself.
 */
function apply(layer: Layer, base: string, files: string[], upperS: string, report: UpstreamReport): void {
  for (const rel of files) {
    const ours = readFile(join(layer.s, rel));
    const was = readAt(layer.upperRepo, base, layer.upperPrefix, rel);
    const above = readFile(join(upperS, rel));
    const target = join(upperS, rel);
    if (same(ours, was)) {
      report.unchanged.push(rel);
      continue;
    }
    if (ours === null) {
      // Deleted in this layer.
      if (same(above, was)) {
        rmSync(target, { force: true });
        report.applied.push(rel);
      } else {
        report.conflicts.push(rel);
      }
      continue;
    }
    if (same(above, was) || same(above, ours)) {
      mkdirSync(dirname(target), { recursive: true });
      writeFileSync(target, ours);
      report.applied.push(rel);
      continue;
    }
    const m = merge3(above ?? Buffer.alloc(0), was, ours, [`${rel} (above)`, `${rel} (base ${base})`, `${rel} (${basename(layer.dir)})`]);
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, m.text);
    (m.conflicts > 0 ? report.conflicts : report.applied).push(rel);
  }
}

function message(layer: Layer, files: string[]): string {
  return `S: upstream ${files.join(", ")} from ${basename(layer.dir)}`;
}

function toProject(layer: Layer, base: string, files: string[], report: UpstreamReport): void {
  const repo = layer.upperRepo;
  const paths = files.map((f) => `${layer.upperPrefix}/${f}`);
  const dirty = git(repo, "status", "--porcelain", "--", ...paths);
  if (dirty) throw new Error(`uncommitted changes in the project's S/; commit or set them aside first:\n${dirty}`);
  apply(layer, base, files, join(repo, layer.upperPrefix), report);
  if (report.conflicts.length) {
    report.conflictDir = join(repo, layer.upperPrefix);
    return;
  }
  if (!report.applied.length) return;
  const changed = report.applied.map((f) => `${layer.upperPrefix}/${f}`);
  git(repo, "add", "-A", "--", ...changed);
  git(repo, "commit", "-m", message(layer, report.applied), "--", ...changed);
  report.commit = git(repo, "rev-parse", "HEAD");
}

function toShared(layer: Layer, base: string, files: string[], report: UpstreamReport, opts: UpstreamOptions): void {
  const repo = layer.upperRepo;
  const main = opts.mainBranch ?? "main";
  const stamp = new Date().toISOString().replace(/[-:T]/g, "").slice(0, 14);
  const branch = opts.branch ?? `upstream/${basename(layer.dir)}-${stamp}`;
  git(repo, "fetch", "origin", main);
  // A separate worktree, so the project's checkout of shared does not move.
  const wt = join(mkdtempSync(join(tmpdir(), "s-upstream-")), "shared");
  git(repo, "worktree", "add", "-b", branch, wt, `origin/${main}`);
  report.branch = branch;
  apply(layer, base, files, join(wt, "S"), report);
  if (report.conflicts.length) {
    report.conflictDir = join(wt, "S");
    return;
  }
  if (report.applied.length) {
    const changed = report.applied.map((f) => `S/${f}`);
    git(wt, "add", "-A", "--", ...changed);
    git(wt, "commit", "-m", message(layer, report.applied));
    git(wt, "push", "-u", "origin", branch);
    report.pr = (opts.openPr ?? ghPr)({
      cwd: wt,
      base: main,
      head: branch,
      title: message(layer, report.applied),
      body: `Carries ${report.applied.join(", ")} from the S/ of ${basename(layer.dir)} up to shared/S.\n\nThe diff is relative to ${base}, the commit of shared the project last synced to.`,
    });
  }
  git(repo, "worktree", "remove", "--force", wt);
  if (!report.applied.length) git(repo, "branch", "-D", branch);
}

export function upstream(dir: string, fileArgs: string[], opts: UpstreamOptions = {}): UpstreamReport {
  const layer = layerOf(dir);
  const base = readBase(layer);
  if (!base) throw new Error(`${layer.s}/${BASE} is missing; sync the layer first`);
  if (!fileArgs.length) throw new Error("name at least one file of the layer's S/");
  const files = [...new Set(fileArgs.map(normalise))];
  const report: UpstreamReport = { layer, base, applied: [], unchanged: [], conflicts: [] };
  if (layer.kind === "generation") toProject(layer, base, files, report);
  else toShared(layer, base, files, report, opts);
  return report;
}

export function formatUpstream(r: UpstreamReport): string {
  const lines = [`upstream: ${describe(r.layer)}, relative to ${r.base}`];
  if (r.applied.length) lines.push(`  applied: ${r.applied.join(", ")}`);
  if (r.unchanged.length) lines.push(`  unchanged since BASE, nothing to carry: ${r.unchanged.join(", ")}`);
  if (r.conflicts.length)
    lines.push(`  conflicts, nothing committed; markers left in ${r.conflictDir}: ${r.conflicts.join(", ")}`);
  if (r.commit) lines.push(`  committed in the project: ${r.commit}`);
  if (r.pr) lines.push(`  pull request: ${r.pr} (branch ${r.branch})`);
  return lines.join("\n");
}

if (import.meta.main) {
  const [dir, ...files] = process.argv.slice(2);
  if (!dir || !files.length) {
    console.error("usage: bun src/upstream.ts <layer-dir> <file>...");
    process.exit(2);
  }
  const r = upstream(dir, files);
  console.log(formatUpstream(r));
  process.exit(r.conflicts.length ? 1 : 0);
}
