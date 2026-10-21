# Puts where S's step stands beside each message the developer sends, so the session running S
# works from S's own state, not from the chat. Run by the UserPromptSubmit hook in
# .claude/settings.json, beside keep-message.py. It prints one short factual paragraph, which
# Claude Code adds to what the model sees with the message; with no step in progress it prints
# nothing. The spec is S/specs/step.md, "Developer mode".
import glob, json, os, sys

# The project root: this file is <project root>/.claude/hooks/s-state.py.
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CAP = 4000  # Claude Code keeps 10,000 characters of a hook's output; this stays well inside it

try:
    event = json.load(sys.stdin)
except Exception:
    event = {}
text = event.get("prompt") or ""
if text.lstrip().startswith(("<task-notification", "<agent-message", "<system-reminder", "<cross-session-message")):
    sys.exit(0)

logs = glob.glob(os.path.join(ROOT, "S", "steps", "*", "log.jsonl")) + \
       glob.glob(os.path.join(ROOT, "*", "S", "steps", "*", "log.jsonl"))
if not logs:
    sys.exit(0)
log = max(logs, key=os.path.getmtime)
step_dir = os.path.dirname(log)
layer_root = os.path.dirname(os.path.dirname(os.path.dirname(step_dir)))  # <layer>/S/steps/<id>
layer = os.path.basename(layer_root)
lines = [json.loads(l) for l in open(log, encoding="utf-8") if l.strip()]
# A step that completed and was not resumed afterwards is not in progress.
done = [i for i, l in enumerate(lines) if l.get("event") == "step complete"]
if not lines or (done and not any(l.get("event") in ("starts", "resumed") for l in lines[done[-1] + 1:])):
    sys.exit(0)

def gist(path):
    """One entry, in a few words: its id and the field that says what it is."""
    try:
        e = json.load(open(os.path.join(layer_root, path), encoding="utf-8"))
    except Exception:
        return path
    for k in ("finding", "gain", "decision", "text", "outcome", "reason", "input"):
        if isinstance(e.get(k), str) and e[k].strip():
            return f'{e.get("id", path)}: {e[k].strip()[:160]}'
    return str(e.get("id", path))

out = f"S, on {layer}, is in the middle of step {os.path.basename(step_dir)} (S/specs/step.md, developer mode)."
gate = os.path.join(step_dir, "gate")
if os.path.exists(gate):
    g = json.load(open(gate, encoding="utf-8"))
    out += f" Step {g.get('step')} ({g.get('handoffs')}) is done and waits for the developer's answer on what it wrote:"
    for e in g.get("entries", []):
        out += f"\n- {gist(e)}"
    if not g.get("entries"):
        out += " no new entries."
    out += f"\nThe developer's words on this step go into it through S/src/gate.sh; words on anything else are noted for a later step. After it, the step goes on with {g.get('next')}."
else:
    last = lines[-1]
    out += f" Its last event: {last.get('handoff')}: {last.get('event')} ({last.get('detail', '')[:200]})."
print(out[:CAP])
