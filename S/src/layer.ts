// Which layer a directory is, and where the layer above keeps its S/.
//
// A project has `shared` as a git submodule at <project>/shared; the layer above is
// <project>/shared/S. A generation sits inside a project at <project>/<gen>; the layer above is
// <project>/S, in the project's repository.

import { existsSync, readFileSync, realpathSync } from "node:fs";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import { git } from "./git";

export type Layer = {
  kind: "project" | "generation";
  /** The layer's directory. */
  dir: string;
  /** The layer's own S/. */
  s: string;
  /** The git repository that holds the layer above's S/. */
  upperRepo: string;
  /** The path of the layer above's S/ inside `upperRepo`. */
  upperPrefix: string;
};

/** The file in a layer's S/ that records the commit of the layer above it was last synced to. */
export const BASE = "BASE";

export function layerOf(dirArg: string): Layer {
  if (!existsSync(dirArg)) throw new Error(`no such directory: ${dirArg}`);
  const dir = realpathSync(resolve(dirArg));
  const s = join(dir, "S");
  if (existsSync(join(dir, "shared", ".git"))) {
    return { kind: "project", dir, s, upperRepo: join(dir, "shared"), upperPrefix: "S" };
  }
  const project = dirname(dir);
  const top = git(project, "rev-parse", "--show-toplevel");
  const upperPrefix = relative(top, join(project, "S")).split(sep).join("/");
  return { kind: "generation", dir, s, upperRepo: top, upperPrefix };
}

/** The commit recorded in the layer's S/BASE, or null before the first sync. */
export function readBase(layer: Layer): string | null {
  const p = join(layer.s, BASE);
  return existsSync(p) ? readFileSync(p, "utf8").trim() || null : null;
}

export function describe(layer: Layer): string {
  return layer.kind === "project"
    ? `project ${basename(layer.dir)}, from shared/S`
    : `generation ${basename(layer.dir)}, from ${layer.upperPrefix}`;
}
