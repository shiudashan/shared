// sync <layer-dir>: brings the layer above's S/ into the layer's S/.
// The workflow is specified in ../workflows/sync.md.

import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { git, listAt, listDir, merge3, readAt, readFile, same } from "./git";
import { BASE, describe, layerOf, readBase, type Layer } from "./layer";

export type SyncReport = {
  layer: Layer;
  /** The commit of the layer above that the layer was synced from before, or null the first time. */
  from: string | null;
  /** The commit of the layer above that the layer is synced to now, recorded in S/BASE. */
  to: string;
  added: string[];
  updated: string[];
  merged: string[];
  removed: string[];
  /** Files left with conflict markers. */
  conflicts: string[];
  /** Changes above that sync left alone, each with the reason. */
  kept: string[];
};

/** Moves the layer above to its newest commit and returns that commit. */
function advanceUpper(layer: Layer): string {
  if (layer.kind === "project") {
    git(layer.dir, "submodule", "update", "--init", "--remote", "shared");
    return git(layer.upperRepo, "rev-parse", "HEAD");
  }
  return git(layer.upperRepo, "rev-parse", "HEAD");
}

export function sync(dir: string): SyncReport {
  const layer = layerOf(dir);
  const from = readBase(layer);
  const to = advanceUpper(layer);
  const { upperRepo: repo, upperPrefix: prefix } = layer;
  const report: SyncReport = { layer, from, to, added: [], updated: [], merged: [], removed: [], conflicts: [], kept: [] };

  const baseFiles = from ? listAt(repo, from, prefix) : [];
  const newFiles = listAt(repo, to, prefix);
  const paths = [...new Set([...baseFiles, ...newFiles])].filter((p) => p !== BASE).sort();

  for (const rel of paths) {
    const target = join(layer.s, rel);
    const base = from ? readAt(repo, from, prefix, rel) : null;
    const theirs = readAt(repo, to, prefix, rel);
    const ours = readFile(target);
    if (same(base, theirs) || same(ours, theirs)) continue;

    if (theirs === null) {
      // Removed above.
      if (same(ours, base)) {
        rmSync(target);
        report.removed.push(rel);
      } else if (ours !== null) {
        report.kept.push(`${rel}: removed above, kept here because this layer changed it`);
      }
      continue;
    }
    if (ours === null) {
      if (base === null) {
        mkdirSync(dirname(target), { recursive: true });
        writeFileSync(target, theirs);
        report.added.push(rel);
      } else {
        report.kept.push(`${rel}: changed above, left deleted because this layer deleted it`);
      }
      continue;
    }
    if (same(ours, base)) {
      writeFileSync(target, theirs);
      report.updated.push(rel);
      continue;
    }
    const m = merge3(ours, base, theirs, [`${rel} (this layer)`, `${rel} (base ${from ?? "none"})`, `${rel} (above, ${to})`]);
    writeFileSync(target, m.text);
    (m.conflicts > 0 ? report.conflicts : report.merged).push(rel);
  }

  mkdirSync(layer.s, { recursive: true });
  writeFileSync(join(layer.s, BASE), `${to}\n`);
  return report;
}

export function formatSync(r: SyncReport): string {
  const lines = [`sync: ${describe(r.layer)}`, `  from ${r.from ?? "(first sync)"} to ${r.to}, recorded in S/${BASE}`];
  const list = (name: string, xs: string[]) => xs.length && lines.push(`  ${name}: ${xs.join(", ")}`);
  list("added", r.added);
  list("updated", r.updated);
  list("merged", r.merged);
  list("removed", r.removed);
  list("conflicts, markers left in the file", r.conflicts);
  for (const k of r.kept) lines.push(`  kept: ${k}`);
  if (!r.added.length && !r.updated.length && !r.merged.length && !r.removed.length && !r.conflicts.length)
    lines.push("  nothing changed above");
  lines.push(
    r.conflicts.length
      ? "  Resolve the conflicts, then review and commit."
      : "  Review and commit.",
  );
  return lines.join("\n");
}

if (import.meta.main) {
  const dir = process.argv[2];
  if (!dir || process.argv.length > 3) {
    console.error("usage: bun src/sync.ts <layer-dir>");
    process.exit(2);
  }
  const r = sync(dir);
  console.log(formatSync(r));
  process.exit(r.conflicts.length ? 1 : 0);
}
