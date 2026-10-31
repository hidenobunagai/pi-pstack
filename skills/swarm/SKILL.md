---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
---

# Swarm

## Start

Open a todo checklist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Pick the worker model from the `swarm_workers` role. For a model race, name each arm's route up front. Per the shared rule below.

**Child routes go on each call.** Before the first spawn in a session, make sure the `subagent` tool is active, calling `subagents_enable({})` once if only the loader is exposed. Pass the role's route from `config/models.yml` of this repo (or the user's `~/.pi/pstack-models.yml`) as one `model` string, `<provider>/<model>:<effort>`. When Pi rejects a route (an unknown id, or one outside an enforced `subagents.modelScope`), fall back to the role's default or omit `model` so the child inherits the parent's, say so in the reply, and get the diversity this step needs from the briefs instead. Never pass a field the tool does not declare.

4. Give each worker its own writable output when it writes. When workers verify or measure commits, each brief names the exact revisions. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Launch all N lanes in one `subagent({ workflow: "parallel", args: { tasks: [...] } })` call, so they run concurrently. Each task item is `{ agent: "delegate", task, model }`, with `model` the lane's `<provider>/<model>:<effort>` route, left unset when the role inherits the parent's.

A child cannot ask a question and cannot reach the user's machine beyond this host, so every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. Drop a result that does not record the revisions and method its brief names, and respawn that worker once. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

## Phase D: Report

Return one consolidated in-chat report with the table, issue one-liners, gaps or dropouts, and the race rule when used.
