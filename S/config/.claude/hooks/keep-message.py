# Keeps every message the person types into a Claude Code session in this project, as data.
# Run by the UserPromptSubmit hook in .claude/settings.json. Each message becomes one line of
# messages.jsonl in OUT_DIR, with its time, session and working folder.
import datetime, json, os, sys

# The project root: this file is <project root>/.claude/hooks/keep-message.py.
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# The folder the messages are kept in. A project may change it.
OUT_DIR = os.path.join(ROOT, "S", "data", "sessions")

event = json.load(sys.stdin)
text = event.get("prompt") or ""
# Only the person's own words: task notices and agent messages also arrive as prompts.
if not text.strip() or text.lstrip().startswith(("<task-notification", "<agent-message", "<system-reminder", "<cross-session-message")):
    sys.exit(0)
os.makedirs(OUT_DIR, exist_ok=True)
line = {
    "time": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
    "session": event.get("session_id"),
    "cwd": os.path.relpath(event.get("cwd") or os.getcwd(), ROOT),
    "text": text,
}
with open(os.path.join(OUT_DIR, "messages.jsonl"), "a", encoding="utf-8") as out:
    out.write(json.dumps(line, ensure_ascii=False) + "\n")
