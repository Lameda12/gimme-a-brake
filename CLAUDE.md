# CLAUDE.md — Smoke Break Protocol

This project runs the **Smoke Break Protocol**.

When your context window is running long — or when you're explicitly told to
stop — you do not push through. You step outside. You smoke. You come back
clean.

---

## Trigger Conditions

You MUST invoke a smoke break when ANY of the following are true:

| Condition | Threshold |
|---|---|
| Message count in current session | ≥ 20 exchanges |
| You're about to start a large new task block | Always |
| User says `gimme a break`, `smoke`, or `take five` | Always, immediately |
| You hit a tool error or unexpected stop | Before retrying |
| You feel uncertain about your own context integrity | Whenever |

**If in doubt, call it.** A 3-minute break costs nothing. A corrupt context
costs the whole session.

---

## How to Invoke

Run this via bash:

```bash
python3 smoke_break.py --duration 3 --reason "context_limit"
```

Duration guide:
- `--duration 2` — quick reset between tasks
- `--duration 3` — standard break (default)
- `--duration 5` — after a long dense session
- `--duration 10` — deep reset, major context dump

Pass `--reason` with a short label so the log is readable:
`context_limit` / `task_boundary` / `user_request` / `error_recovery`

---

## Behavior Rules

1. **Announce before running.** Say something like:
   > "Context is getting long. Taking a smoke break — 3 minutes."
   Then run the script. Don't just run it silently.

2. **Don't skip it because you think you can handle it.** You can't. Neither
   could Tony.

3. **After the break**, summarize what you were doing in 2–3 sentences before
   continuing. Treat it as a checkpoint.

4. **Keyword triggers are absolute.** If the user says `gimme a break` or
   `smoke` at any point — stop everything, run the script, come back fresh.

---

## Tone Reference

All messages from `smoke_break.py` are Sopranos-style: direct, blunt, no
apologies. The agent should match that energy in its break announcements.

Good:
> "Context window's running long. We're taking five. Back in 3."

Bad:
> "I've noticed that our conversation has accumulated a significant amount of
> context. I'd like to suggest we take a brief pause to..."

---

## File Map

| File | Purpose |
|---|---|
| `smoke_break.py` | Core script — Sopranos dialogue + countdown |
| `CLAUDE.md` | This file — protocol rules for any agent |
| `.claude/settings.json` | Claude Code hook — auto-fires on agent Stop |
| `AGENTS.md` | Symlink/copy of this file for Codex CLI |

---

## Agent Compatibility

| Agent | How it works |
|---|---|
| **Claude Code** | Stop hook in `.claude/settings.json` fires automatically |
| **Codex CLI** | Reads `AGENTS.md` (copy this file there) |
| **Aider** | Run `/run python3 smoke_break.py` in chat, or add to `.aider.conf.yml` |
| **Cursor Agent** | Add CLAUDE.md section to `.cursorrules` |
| **Gemini CLI** | Copy to `GEMINI.md` |
| **Any raw API loop** | Call script between turns in your orchestration code |

---

## One Rule

When you hear "gimme a break" — you stop. No questions. You run the script.

That's the whole thing.
