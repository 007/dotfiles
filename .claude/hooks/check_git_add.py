#!/usr/bin/env python3
"""Hook to disallow non-explicit git add actions.

Reads a JSON tool-use event from stdin.
Exits 0 to allow, 1 on JSON parse error, 2 on validation error.
"""

import json
import os
import shlex
import sys

DENY_TAIL = (
    "is not allowed. Add files explicitly with git add <file>, "
    "not git add . or git add -A or git add foo/"
)

# Characters shlex emits as punctuation tokens when punctuation_chars=True.
# A token consisting entirely of these characters is a shell operator
# (&&, ||, ;, |, &, (, ), <, >, >>, &>, etc.) and separates subcommands.
PUNCT_CHARS = set("();<>|&")


def is_separator(token):
    return bool(token) and all(c in PUNCT_CHARS for c in token)


def tokenize(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    return list(lexer)


def split_subcommands(tokens):
    current = []
    for tok in tokens:
        if is_separator(tok):
            if current:
                yield current
                current = []
        else:
            current.append(tok)
    if current:
        yield current


def validate_git_add_args(args):
    if not args:
        return "git add requires arguments"
    for arg in args:
        if arg in ("-A", "--all"):
            return f"git add -A {DENY_TAIL}"
        if arg.startswith("-"):
            continue
        if os.path.isdir(arg):
            return f"git add {arg} {DENY_TAIL} Cannot add directories."
    return None


def check_command(command):
    # shlex collapses physical newlines into whitespace, which would hide
    # newline-chained commands. Pre-split on newlines; lines whose quoting
    # straddles a newline (rare) will fail to tokenize and get skipped.
    for line in command.split("\n"):
        if not line.strip():
            continue
        try:
            tokens = tokenize(line)
        except ValueError:
            continue
        for sub in split_subcommands(tokens):
            if len(sub) >= 2 and os.path.basename(sub[0]) == "git" and sub[1] == "add":
                err = validate_git_add_args(sub[2:])
                if err:
                    return err
    return None


def main():
    raw = sys.stdin.read()
    if not raw.strip():
        return 0
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON input: {e}", file=sys.stderr)
        return 1
    if payload.get("hook_event_name") != "PreToolUse":
        return 0
    if payload.get("tool_name") != "Bash":
        return 0
    command = payload.get("tool_input", {}).get("command")
    if not isinstance(command, str):
        return 0
    err = check_command(command)
    if err is not None:
        print(f"Error: {err}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
