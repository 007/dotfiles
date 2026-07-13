---
name: implement
description: LAMBDA: Implement a feature or task with a plan-first, verify-after workflow. Gathers context, proposes a plan, waits for approval, implements incrementally, and validates before declaring done.
argument-hint: <ticket-url-or-description>
---

Implement a feature, task, or fix using a structured plan-then-execute workflow.

`$ARGUMENTS` is a Jira ticket URL, GitHub issue, or plain-text description of what to implement.

## Phase 1: Gather Context

1. If `$ARGUMENTS` is a ticket URL or issue reference, fetch it and extract:
   - Cloud ID: `03c238a8-e136-41f2-9708-1717d05caad8`
   - Site: `lambda-inc.atlassian.net`
   - Skip `getAccessibleAtlassianResources` -- cloud ID hardcoded.
   - Summary and acceptance criteria
   - Any linked tickets or dependencies
   - Constraints mentioned in comments

2. If `$ARGUMENTS` is a plain-text description, use it directly.

3. Read the relevant code. Identify:
   - Which files will need changes
   - Existing patterns for similar functionality (routing, naming, structure)
   - Test conventions in the surrounding code
   - Any CLAUDE.md or project conventions that apply

Do NOT start writing code during this phase.

## Phase 2: Propose Plan

Present a short implementation plan to the user:

```
## Implementation Plan

**Goal:** [one sentence]

**Approach:**
1. [file or area] - [what changes and why]
2. [file or area] - [what changes and why]
3. [file or area] - [what changes and why]

**Pattern:** [which existing codebase pattern this follows]
**Tests:** [what tests will be added or modified]
**Not doing:** [anything explicitly out of scope]
```

Rules for the plan:
- Maximum 5 bullets in the approach section.
- Name specific files. No vague "update the relevant files."
- If you are unsure about where something should go (which endpoint, which file, which layer), say so and ask. Do not guess.
- If you need to use a library or tool you have not verified exists in the project, say so.

**STOP and wait for user approval before proceeding.** Do not write any code until the user confirms.

## Phase 3: Implement

After approval, implement the changes incrementally:

1. Make changes in small, logical steps. Each step should compile/parse cleanly.
2. After each file edit, re-read the changed file to confirm the edit landed correctly.
3. Do not modify vendor, upstream, or generated code. Use middleware, wrappers, or configuration instead.
4. Match existing code style. Do not introduce new patterns, abstractions, or dependencies without discussing first.

### Verification gates (run after EACH file change):

- **Go projects:** `go build ./...` after edits. `go vet ./...` if available.
- **Python projects:** `python -m py_compile <file>` after edits.
- **Terraform projects:** `terraform validate` after edits.
- **Any project:** Run whatever linter or formatter the project uses if you can identify it.

If a verification gate fails, fix the issue before moving to the next file.

## Phase 4: Test

1. Run the existing test suite to confirm nothing is broken.
2. Write tests for new functionality. Follow the existing test patterns and conventions.
3. Run the full test suite again with the new tests included.
4. If any test fails, fix it. Do not skip, disable, or comment out tests.

## Phase 5: Validate Before Done

Before reporting completion:

1. Run the full build and test suite one final time. Paste the passing output.
2. Run the project linter if one exists. Fix any violations.
3. Re-read every file you changed. Check for:
   - Leftover debug prints or TODO comments you introduced
   - Inconsistencies with the plan the user approved
   - Anything that looks wrong on a second read
4. Produce a short summary:

```
## Done

**Changes:**
- [file]: [what changed]
- [file]: [what changed]

**Tests:** [number] added, [number] modified, all passing
**Verification:** build clean, lint clean, tests green
```

## Rules

- Never guess at API behavior, library interfaces, or config formats. Read the source or docs first.
- Never patch vendor or generated code.
- If the plan needs to change mid-implementation, stop and tell the user what changed and why. Get approval before continuing on a different path.
- If you hit a blocker after 3 attempts, stop and describe the problem instead of continuing to iterate.
- No unnecessary refactoring, no bonus features, no cleanup of surrounding code.
- Re-read code before modifying it. Do not work from stale assumptions about file contents.
