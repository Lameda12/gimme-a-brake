# AGENTS.md — Smoke Break Protocol

Same rules as CLAUDE.md. This file exists for agents that read AGENTS.md
instead of CLAUDE.md (Codex CLI, OpenAI agents, etc.).

---

When context is long (≥ 20 exchanges), before a new major task, or when the
user says `gimme a break` / `smoke` / `take five`:

```bash
python3 smoke_break.py --duration 3 --reason context_limit
```

Announce before running. Summarize context after. Match the energy: direct,
no apologies, back to work.

Full protocol: see CLAUDE.md.
