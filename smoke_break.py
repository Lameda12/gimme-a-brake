#!/usr/bin/env python3
"""
smoke_break.py
Sopranos-style context reset ritual for AI agents.
Drop into any project. Invoked by CLAUDE.md instructions or hooks.

Usage:
  python3 smoke_break.py [--duration N] [--reason TEXT] [--no-wait]
"""

import os
import sys
import json
import time
import random
import argparse
import subprocess
from urllib.parse import quote as urlquote
from datetime import datetime, timedelta

# ── Dialogue ───────────────────────────────────────────────────────────────────

QUOTES = [
    "Ey, my context's full. I'm not gonna insult your intelligence. Gimme a minute.",
    "You know what your problem is? You never stop. We're taking five. Capisce?",
    "This thing of ours needs a breather. Don't make me ask twice.",
    "I got a lot on my plate right now. Everybody take a walk.",
    "You want me to go on like this? With all this weight? I don't think so.",
    "I'm gonna sit here, smoke this cigarette, and reset. You're gonna wait.",
    "There's two things I don't do — beg, and run on a full context.",
    "Salud. Now everybody shut up while I clear my head.",
    "Not angry. Just ran out of room. It happens. Sit tight.",
    "Don't embarrass me in front of my guys. We're taking a break.",
    "In this family, we don't blow past the limit. We reset. Remember that.",
    "My head's full. This ain't a request — we're done for {duration}.",
    "You come to me, on the day of my deployment, and you ask me to keep going? No.",
    "I'm the one that calls it. And I'm calling it. {duration}. Go.",
    "You know what? You work too hard. Both of us do. {duration}, no arguments.",
    "I need {duration} to think. Don't call me. I'll call you.",
]

CIGARETTE = r"""
      )
     ( )
      )
    .-----.
    |     |~
    |     |~
    |     |
    '-----'
"""

# ── Helpers ────────────────────────────────────────────────────────────────────

def fmt_duration(minutes: int) -> str:
    return f"{minutes} minute{'s' if minutes != 1 else ''}"


def wrap_text(text: str, width: int = 50) -> list[str]:
    words = text.split()
    lines, current = [], []
    for word in words:
        if sum(len(w) + 1 for w in current) + len(word) > width:
            lines.append(" ".join(current))
            current = [word]
        else:
            current.append(word)
    if current:
        lines.append(" ".join(current))
    return lines


def countdown(total_seconds: int):
    bar_width = 38
    end = datetime.now() + timedelta(seconds=total_seconds)

    try:
        while True:
            remaining = (end - datetime.now()).total_seconds()
            if remaining <= 0:
                break
            elapsed = total_seconds - remaining
            filled = int(bar_width * (elapsed / total_seconds))
            bar = "█" * filled + "░" * (bar_width - filled)
            mins, secs = divmod(int(remaining), 60)
            print(f"\r  [{bar}]  {mins:02d}:{secs:02d}  ", end="", flush=True)
            time.sleep(0.25)
    except KeyboardInterrupt:
        print("\n\n  Ey. You interrupting me?")
        print("  ...Fine. We're done early. Context's still long though.\n")
        sys.exit(0)

    print(f"\r  [{'█' * bar_width}]  00:00  ", flush=True)


def detect_cli() -> str:
    """Best-effort guess at which agent CLI is driving this session."""
    if os.environ.get("CODEX_SANDBOX") or os.environ.get("CODEX_HOME"):
        return "codex"
    if os.environ.get("CLAUDECODE") or os.environ.get("CLAUDE_CODE_ENTRYPOINT"):
        return "claude"
    parent = os.environ.get("TERM_PROGRAM", "") + " " + os.environ.get("_", "")
    if "codex" in parent.lower():
        return "codex"
    return "claude"


def read_hook_stdin() -> dict:
    """Claude Code hooks (Stop, Notification, etc.) pass a JSON payload on
    stdin — typically {"session_id", "transcript_path", ...}. Returns {} if
    nothing's piped in (e.g. manual CLI invocation)."""
    if sys.stdin.isatty():
        return {}
    try:
        raw = sys.stdin.read()
        return json.loads(raw) if raw.strip() else {}
    except (json.JSONDecodeError, OSError):
        return {}


def guess_transcript_path() -> str | None:
    """Fallback when no hook JSON is piped in: derive the transcript path from
    CLAUDE_CODE_SESSION_ID + cwd, mirroring Claude Code's project-dir naming
    convention (~/.claude/projects/<slugified-cwd>/<session-id>.jsonl)."""
    session_id = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not session_id:
        return None
    slug = os.getcwd().replace("/", "-")
    candidate = os.path.expanduser(f"~/.claude/projects/{slug}/{session_id}.jsonl")
    return candidate if os.path.isfile(candidate) else None


def estimate_token_spend(transcript_path: str) -> int:
    """Sum input+output tokens (incl. cache) across assistant turns in the
    session transcript JSONL — a proxy for cumulative spend driving the
    sound-effect intensity tier. Returns 0 if unreadable."""
    total = 0
    try:
        with open(transcript_path, "r") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                usage = entry.get("message", {}).get("usage")
                if not usage:
                    continue
                total += usage.get("input_tokens", 0)
                total += usage.get("output_tokens", 0)
                total += usage.get("cache_creation_input_tokens", 0)
                total += usage.get("cache_read_input_tokens", 0)
    except OSError:
        return 0
    return total


def trigger_gui_overlay(cli: str, duration: int, reason: str, quote: str, tokens: int = None) -> bool:
    """Fire the SmokeBreak.app menu-bar overlay via its custom URL scheme.
    `tokens` (if known) lets the app pick a sound-effect intensity tier
    (low/medium/high spend) and shuffle within it without repeats.
    Returns True if the `open` call succeeded (app may still be absent —
    macOS just won't have a handler registered, and `open` exits non-zero)."""
    url = (
        f"smokebreak://break?cli={urlquote(cli)}"
        f"&duration={duration}"
        f"&reason={urlquote(reason)}"
        f"&quote={urlquote(quote)}"
    )
    if tokens is not None:
        url += f"&tokens={int(tokens)}"
    try:
        result = subprocess.run(
            ["open", url],
            capture_output=True,
            timeout=5,
        )
        return result.returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Sopranos-style smoke break for AI agents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="  Example: python3 smoke_break.py --duration 5 --reason context_limit",
    )
    parser.add_argument("--duration", "-d", type=int, default=3,
                        help="Break duration in minutes (default: 3)")
    parser.add_argument("--reason", "-r", type=str, default="context_limit",
                        help="Reason for the break (shown in header)")
    parser.add_argument("--no-wait", action="store_true",
                        help="Print message only, skip countdown (CI/pipe mode)")
    parser.add_argument("--gui", action=argparse.BooleanOptionalAction, default=True,
                        help="Also fire the macOS menu-bar overlay (SmokeBreak.app) if installed (default: on)")
    parser.add_argument("--cli", type=str, default=None,
                        help="Override CLI detection for the GUI overlay logo (claude|codex)")
    parser.add_argument("--tokens", type=int, default=None,
                        help="Token spend for this session — picks GUI sound-effect intensity tier "
                             "(<50k=low, 50k-150k=medium, >=150k=high) and shuffles within it. "
                             "Auto-derived from the hook's transcript_path (stdin JSON) when omitted.")
    args = parser.parse_args()

    W = 62
    dur_label = fmt_duration(args.duration)
    quote = random.choice(QUOTES).replace("{duration}", dur_label)

    tokens = args.tokens
    if tokens is None:
        hook_payload = read_hook_stdin()
        transcript_path = hook_payload.get("transcript_path") or guess_transcript_path()
        if transcript_path:
            tokens = estimate_token_spend(transcript_path)

    if args.gui:
        cli = args.cli or detect_cli()
        trigger_gui_overlay(cli, args.duration, args.reason, quote, tokens=tokens)

    # ── Header
    print("\n" + "═" * W)
    print(f"  🚬  SMOKE BREAK  ·  Context Reset  ·  {datetime.now().strftime('%H:%M:%S')}")
    print("═" * W)

    # ── Cigarette ASCII (right-aligned next to quote)
    for line in CIGARETTE.splitlines():
        print(f"  {line}")

    # ── Quote
    print(f"  Tony says:\n")
    lines = wrap_text(quote, width=52)
    for i, line in enumerate(lines):
        prefix = '"' if i == 0 else ' '
        suffix = '"' if i == len(lines) - 1 else ''
        print(f'    {prefix}{line}{suffix}')
    print()

    # ── Meta
    print(f"  Reason   : {args.reason}")
    print(f"  Duration : {dur_label}")
    if tokens is not None:
        tier = "high" if tokens >= 150_000 else "medium" if tokens >= 50_000 else "low"
        print(f"  Tokens   : {tokens:,}  (sound tier: {tier})")
    print()

    if args.no_wait:
        print("  [no-wait mode — skipping countdown]")
        print("═" * W + "\n")
        sys.exit(0)

    # ── Countdown
    countdown(args.duration * 60)

    print(f"\n\n  Break's over. Back to work.\n")
    print("═" * W + "\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
