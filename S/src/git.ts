// Small helpers over git, shared by sync and upstream.

import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export type Run = { code: number; stdout: Buffer; stderr: string };

export function run(cmd: string[], cwd: string): Run {
  const p = Bun.spawnSync({ cmd, cwd, env: { ...process.env }, stdout: "pipe", stderr: "pipe" });
  return { code: p.exitCode ?? -1, stdout: Buffer.from(p.stdout), stderr: p.stderr.toString() };
}

/** Runs git in `cwd` and returns stdout as text. Throws with git's message on failure. */
export function git(cwd: string, ...args: string[]): string {
  const r = run(["git", ...args], cwd);
  if (r.code !== 0) throw new Error(`git ${args.join(" ")} (in ${cwd}) failed: ${r.stderr.trim()}`);
  return r.stdout.toString().trim();
}

/** The files under `prefix/` at `commit`, as paths relative to `prefix`. */
export function listAt(repo: string, commit: string, prefix: string): string[] {
  const r = run(["git", "ls-tree", "-r", "-z", "--name-only", commit, "--", `${prefix}/`], repo);
  if (r.code !== 0) throw new Error(`git ls-tree ${commit} ${prefix} failed: ${r.stderr.trim()}`);
  return r.stdout
    .toString()
    .split("\0")
    .filter((p) => p.length > 0)
    .map((p) => p.slice(prefix.length + 1));
}

/** The content of `prefix/rel` at `commit`, or null when the file does not exist there. */
export function readAt(repo: string, commit: string, prefix: string, rel: string): Buffer | null {
  const r = run(["git", "show", `${commit}:${prefix}/${rel}`], repo);
  return r.code === 0 ? r.stdout : null;
}

export function readFile(path: string): Buffer | null {
  return existsSync(path) ? readFileSync(path) : null;
}

/** Every file under `dir`, relative to it, skipping `.git`. */
export function listDir(dir: string, sub = ""): string[] {
  if (!existsSync(dir)) return [];
  const out: string[] = [];
  for (const name of readdirSync(join(dir, sub))) {
    if (name === ".git") continue;
    const rel = sub ? `${sub}/${name}` : name;
    if (statSync(join(dir, rel)).isDirectory()) out.push(...listDir(dir, rel));
    else out.push(rel);
  }
  return out;
}

export function same(a: Buffer | null, b: Buffer | null): boolean {
  if (a === null || b === null) return a === b;
  return a.equals(b);
}

/**
 * Three-way merge with `git merge-file`: the changes from `base` to `theirs` are applied onto
 * `ours`. A missing base counts as an empty file.
 */
export function merge3(
  ours: Buffer,
  base: Buffer | null,
  theirs: Buffer,
  labels: [string, string, string],
): { text: Buffer; conflicts: number } {
  const dir = mkdtempSync(join(tmpdir(), "s-merge-"));
  try {
    const [o, b, t] = ["ours", "base", "theirs"].map((n) => join(dir, n));
    writeFileSync(o, ours);
    writeFileSync(b, base ?? Buffer.alloc(0));
    writeFileSync(t, theirs);
    const r = run(["git", "merge-file", "-p", "-L", labels[0], "-L", labels[1], "-L", labels[2], o, b, t], dir);
    if (r.code < 0 || r.code > 127) throw new Error(`git merge-file failed: ${r.stderr.trim()}`);
    return { text: r.stdout, conflicts: r.code };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
