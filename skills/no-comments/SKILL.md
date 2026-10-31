---
name: no-comments
description: "Spawn Comment Sicko, fix accepted findings, and offer encodings for claimed constraints."
---

# No comments

Spawn Comment Sicko. Act on accepted findings.

Defer to Comment Sicko's fresh perspective.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

## Steps

1. Spawn one `subagent` with `agent: "delegate"`. Pi has no comment-sicko agent type, so paste the full text of `references/comment-sicko.md` into the task as the role, then pass the scope. Take the route from the `judgment` role, preferring a family other than the one that wrote the code, since a fresh family keeps the reviewer from defending its own prose. Per the shared rule below.

**Child routes go on each call.** Before the first spawn in a session, make sure the `subagent` tool is active, calling `subagents_enable({})` once if only the loader is exposed. Pass the role's route from `config/models.yml` of this repo (or the user's `~/.pi/pstack-models.yml`) as one `model` string, `<provider>/<model>:<effort>`. When Pi rejects a route (an unknown id, or one outside an enforced `subagents.modelScope`), fall back to the role's default or omit `model` so the child inherits the parent's, say so in the reply, and get the diversity this step needs from the briefs instead. Never pass a field the tool does not declare. Do not restate its rules.

2. Inspect its report and diff. Reject application-code edits, scope escapes, exception-protected deletions, misstated `MUST KILL` reasons, and flags that treat kept intentional code as guilty. Reshape flags on our-code surprises stay actionable. Do not restore those comments. A keep survives only with proof it is about something we cannot change. Audit missed scoped lint and TypeScript suppressions. Correctness or safety suppressions stay actionable `MUST KILL`s. Restore deletions only with exact exceptions and scoped proof. Before accepting thin `IMPORTANT` or `do not remove` kills or keeps, run the `how` or `why` skill on their symbol. If a kill is ambiguous, do not restore. If a keep is refuted or still ambiguous, delete it. Revert and rerun one rejected report with the failure named. Reject a second, report it open, and report the pass as failed.
3. Fix trivial accepted flags directly by deleting a dead path, dropping a parameter, or using the real API. If any fix needs a shape, run the `architect` skill once for the accepted set and surrounding code. Stop at the sketch. Architect shapes. Step 4 implements.
4. Implement the smallest root-cause fix in scope. Remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. The **principle-fix-root-causes** and **principle-redesign-from-first-principles** skills guide intent only. Neither authorizes widening the fence nor fixing instances outside it. Never bolt on symptom guards.
5. Constraint comments say `do not remove`, `do not change wording`, or `talk to X before changing`. Leave keeps about things we cannot change. Keep `ponytail:` comments that name a ceiling and an upgrade path. Offer the cheapest in-scope type, runtime, test, or CI lint. Wait for interactive approval. Unattended and eval require caller pre-approval. If approved, encode then delete. Otherwise delete, report the constraint open, and sketch out-of-scope work.
6. Report the deletion count, restored comments, reruns, architect sketch, fixes, encoding offers, encodings, unenforced constraints, and other open work.
