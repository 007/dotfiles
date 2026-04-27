---
name: code-review
description: Run a multi-perspective code review of current changes. Spawns junior (file/function), mid (module/interface), and senior (architecture/system) review agents in parallel, then synthesizes findings into a unified review.
argument-hint: [target]
disable-model-invocation: true
---

Run a comprehensive code review from three perspectives against the current changes.

If `$ARGUMENTS` is provided, scope the review to that target (file path, directory, or branch diff). Otherwise, review all staged and unstaged changes (`git diff` and `git diff --cached`).

## Process

1. Launch all three code-review agents **in parallel** using the Task tool:
   - `code-review-junior` -- file and function level review
   - `code-review-mid` -- module and interface level review
   - `code-review-senior` -- architecture and system level review

   Each agent should receive the same diff/target context. Pass the full diff content or file paths in the agent prompt so each agent has what it needs.

2. Collect results from all three agents.

3. Synthesize a single unified review with this structure:

```
## Code Review

### Critical Issues
[Deduplicated critical findings from all three perspectives. Include source perspective in parentheses.]

### Recommendations
[Deduplicated recommendations, grouped by theme. Include source perspective.]

### Strengths
[Notable positives worth calling out.]

### Opportunities
[Optional improvements, low priority.]

### Summary
[2-3 sentence overall assessment covering implementation quality, module design, and architectural impact.]
```

## Rules

- Deduplicate overlapping findings across perspectives. If two agents flag the same issue, merge them and note both perspectives.
- Order findings by severity, not by source agent.
- Use plain text. No emojis in the output.
- Keep the synthesized review concise. Cut redundancy aggressively.
- If there are no changes to review, say so and stop.
