---
name: reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## 1. Locate the active transcript

Pi keeps sessions under `${PI_CODING_AGENT_DIR:-~/.pi/agent}/sessions/<encoded-cwd>/<timestamp>_<session-id>.jsonl`, one plain JSONL file per session.

```bash
f=$(ls -t "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"/sessions/--$(echo "${PWD#/}" | tr '/:' '--')--/*.jsonl 2>/dev/null | head -1)
head -5 "$f"
```

Pick the session whose first user message matches this conversation's opening prompt. If none matches, or the path cannot be resolved, pass a tight digest of the session instead. Do not read sessions from other workspaces.

## 2. Spawn three reviewers in parallel

One `subagent` call with `workflow: "parallel"` and three tasks, one per lens. Each brief states that the reviewer may read freely and must not edit skill files, since skill edits land only after approval in step 5.

Each reviewer and the synthesizer take their routes from the `reflect_lenses` and `reflect_synthesizer` roles. The three lenses already differ in prompt, so model diversity is a bonus rather than the mechanism. Per the shared rule below.

**Child routes go on each call.** Before the first spawn in a session, make sure the `subagent` tool is active, calling `subagents_enable({})` once if only the loader is exposed. Pass the role's route from `config/models.yml` of this repo (or the user's `~/.pi/pstack-models.yml`) as one `model` string, `<provider>/<model>:<effort>`. When Pi rejects a route (an unknown id, or one outside an enforced `subagents.modelScope`), fall back to the role's default or omit `model` so the child inherits the parent's, say so in the reply, and get the diversity this step needs from the briefs instead. Never pass a field the tool does not declare.

| Lens      | Seat                    | Prompt template (relative to this file) |
| --------- | ----------------------- | --------------------------------------- |
| Judgment  | `reflect_lenses` seat 1 | `references/judgment-reviewer.md`       |
| Tooling   | `reflect_lenses` seat 2 | `references/tooling-reviewer.md`        |
| Divergent | `reflect_lenses` seat 3 | `references/divergent-reviewer.md`      |

Pass each template verbatim, substituting the transcript content or digest where marked. Reviewers return findings in their final message.

## 3. Synthesize

One `subagent` call on the `reflect_synthesizer` role. It spot-verifies citations against the transcript and the referenced files. Pass `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. It returns an Accepted / Rejected / Backlog list.

## 4. Structural enforcement check

Move any Accepted item that a lint rule, script, metadata flag, or runtime check would enforce more reliably to Backlog. See the **encode-lessons-in-structure** principle skill.

## 5. Apply

Present the synthesizer's full Accepted / Rejected / Backlog output and wait for explicit approval before applying any Accepted edit. Ask in the reply, with the Accepted rows as a numbered list of options, and end the turn. The user picks the subset and may redirect routings. Skill changes affect every future session. Do not auto-apply.

Follow each approved row's Routing exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): the parent does it directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): write it as a proposal and get approval before writing the file.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): rewrite the frontmatter `description` so its trigger words match how the user actually asks.
- `new skill via authoring: <kebab-name>`: create `skills/<name>/SKILL.md` in this repo, run `scripts/check-skills.mjs`, and install with `scripts/link-skills.sh`.

Run `scripts/check-skills.mjs` on every touched skill before declaring done.

## 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog: `<item>`. One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
