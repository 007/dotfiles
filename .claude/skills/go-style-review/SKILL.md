---
name: go-style-review
description: Use when reviewing Go code against the Google Go Style Guide, when the user asks for a Google-style review of Go code, or when assessing Go changes that must follow Google conventions (internal Google codebases, projects that adopt the guide).
---

# Go Style Review (Google Style Guide)

## Overview

The Google Go Style Guide (https://google.github.io/styleguide/go/guide) ranks five principles in strict priority order:

1. **Clarity** - purpose and rationale are apparent
2. **Simplicity** - simplest viable approach, least mechanism
3. **Concision** - high signal-to-noise, no redundancy
4. **Maintainability** - correct modifications are easy
5. **Consistency** - matches codebase conventions

Higher principles override lower ones. Consistency is the tiebreaker.

A single reviewer reading a file sequentially tends to anchor on the first 2-3 issues they notice and miss the rest. This skill runs five independent reviews - one per principle - in parallel, then consolidates. Each reviewer is blind to the others' findings until consolidation.

## When to Use

- Reviewing a Go file, package, or diff for Google-style compliance.
- PR reviews on Go code intended to follow Google conventions.
- Pre-commit sanity check on Go changes.

Do not use when the project has documented deviations from Google style (always honor the local codebase's conventions per guide#local-consistency). Do not use on non-Go code.

## Process

1. **Scope the target.** Identify which files or diff to review. If the target is a diff, extract the changed hunks. If it's a package, read the `.go` files (excluding generated files like `*.pb.go` unless explicitly in scope).

2. **Dispatch five subagents in parallel** using the `Agent` tool (see superpowers:dispatching-parallel-agents). All five calls happen in one message so they run concurrently. Each subagent already carries its own lens prompt - pass only the target code. Use these `subagent_type` values:

   - `go-style-clarity`
   - `go-style-simplicity`
   - `go-style-concision`
   - `go-style-maintainability`
   - `go-style-consistency`

   Each subagent prompt should be of the form:

   ```
   Review the following Go target against your assigned lens.

   File: <path>
   ```go
   <full file contents, or diff hunk>
   ```
   ```

   Pass the target code inline. Do not pass file paths alone; subagents may not have read access to the paths.

3. **Collect and consolidate.** When all five return, merge their findings using the template below. Deduplicate line-overlapping findings: keep the highest-priority lens's version (clarity wins over simplicity wins over concision, etc.). Cross-reference in parentheses when a line appears in multiple lenses.

4. **Output the consolidated review.** Order findings within each lens by impact (highest first), and order the lenses in their priority order.

## Consolidation Template

```
## Go Style Review (Google Style Guide)

### Clarity
<findings from clarity subagent, highest-impact first>

### Simplicity
<findings from simplicity subagent>

### Concision
<findings from concision subagent>

### Maintainability
<findings from maintainability subagent>

### Consistency
<findings from consistency subagent>

### Summary
<2-3 sentences: total finding count, where issues cluster, any blockers (violations of clarity or simplicity that should be fixed before merge)>
```

Each finding under a lens should retain its `file:line - rule - description / Fix: ...` format from the subagent.

## Rules

- **Cite specific style-guide sections** in every finding (e.g., `decisions#error-strings`, `best-practices#using-v-vs-w`, `guide#mixedcaps`). Ambiguous citations like "Google style guide says no" are not actionable. Do not invent section anchors; only cite anchors that actually exist at the source URLs.
- **Order within each lens by impact**, not by line number. A missing doc comment on an exported API outranks a misnamed local variable even if the variable appears first.
- **One finding per line, not per rule.** If line 42 violates three rules, surface it once under the highest-priority lens and mention the others parenthetically.
- **No emoji. Plain text. Github-flavored markdown.**
- **If a lens returns `No <principle> findings.`**, include that line in the consolidated output - absence of findings is data.
- **If the target has no Go files, say so and stop.**

## Red Flags

These mean you are about to skip the 5-lens structure. Don't.

| Thought | Reality |
|---------|---------|
| "This change is tiny, one lens is enough" | Every lens takes ~15 seconds in parallel. Dispatch all five. |
| "I can mentally cover all five principles in one read" | You can't. A single reviewer anchors on the first 2-3 issues noticed and predictably misses context-as-first-param, per-identifier doc comments, synchronous-over-async, and nil-slice preference. The five separate lenses exist to force systematic coverage. |
| "Only consistency matters here" | Consistency is the lowest-priority lens. If you're only checking consistency you're missing the important lenses. |
| "I'll inline the lens prompts instead of dispatching subagents" | You'll anchor on whichever lens you read first. The parallel dispatch prevents that anchor. |
| "I'll dispatch sequentially to save tokens" | Sequential dispatch costs more wall time with no token savings, because each subagent's context is disjoint anyway. |

## Common Mistakes

- **Passing file paths to subagents instead of file contents.** Subagents may lack permission to read the path. Paste code into the prompt.
- **Skipping the consolidation dedup.** If the same line appears in three lenses, the reviewer reads it three times. Pick the highest-priority lens and mention others in parentheses.
- **Reporting findings without section citations.** `error strings should be lowercase` is weaker than `decisions#error-strings: error strings should be lowercase`. The citation lets the author verify.
- **Adding findings the subagents didn't produce.** If you notice something during consolidation, note it in the Summary as an additional observation - don't invent a finding under a lens the subagent didn't raise.

## Source

- Style guide: https://google.github.io/styleguide/go/guide
- Style decisions: https://google.github.io/styleguide/go/decisions
- Best practices: https://google.github.io/styleguide/go/best-practices
