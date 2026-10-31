# pi-pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) to [Pi](https://pi.dev) (`@earendil-works/pi-coding-agent`), tuned for this host. Version `0.15.30-pi.1`: ported against upstream 0.15.30 by way of the DSH port (`dsh-pstack`), with `statechart` and the formal verification skills from upstream v0.15.36.

This is an unofficial personal fork. It is not affiliated with or endorsed by the author or Cursor. Provided as-is, with no support. Issues and pull requests may go unanswered. Fork it and make it yours.

pstack is Lauren Tan's (poteto) set of agent workflows: a strict working style, a set of playbooks for the four kinds of engineering work, and skills that encode principles about design, verification, and delegation. The upstream targets Cursor and ships a Claude Code adapter. This repo does the same job for Pi, alongside the sibling ports for Claude Code, agy, and DSH.

## What changes from upstream

The skills keep their behavior. These parts change:

- **Delegation.** Cursor's `Task` tool becomes the `subagent` tool from [pi-subagents](https://github.com/nicobailon/pi-subagents). Every pstack spawn uses the builtin `delegate` agent with the brief as its `task`, and a role's model is one `model` string, `<provider>/<model>:<effort>`, on the call. Panels launch as one `subagent({ workflow: "parallel", ... })` call with a route per item.
- **Models.** Cursor reads role models from `~/.cursor/rules/pstack-models.mdc`. This port reads `config/models.yml`, with a per-user override at `~/.pi/pstack-models.yml`.
- **Version control.** Every repo here is a colocated jj repo, so `git worktree` becomes `jj workspace add`, and stacking uses `jj rebase` / `jj squash`.
- **Invocation.** A pstack slash command such as `/poteto-mode` is `/skill:poteto-mode` in Pi. There is no session hook that pins the mode on, so start each task with it.
- **Verification surfaces.** `control-ui` and `control-cli` from `cursor-team-kit` become `web-verify` for web UIs and a direct run of the real binary for CLIs.
- **Commands.** `/deslop` and `/no-comments` fold into skill passes. `/loop 1h` becomes a pi-subagents schedule (`subagent({ action: "schedule.create", workflow: true, options: { every: "1h" } })`).
- **Todos and questions.** Pi's core tools have no todo list and no question tool, so the playbooks keep their checklist as markdown in the reply and ask the user in plain text.
- **Transcripts and memory.** `recall`, `reflect`, `show-me-your-work`, and the worktree audit read Pi's plain JSONL sessions under `~/.pi/agent/sessions/`. `why` and `recall` search the shared memmini memory first with Pi's native `memory_search`.

The full mapping, including every table, is in [`docs/harness/pi.md`](docs/harness/pi.md). Read that once per session before following a playbook.

Left out on purpose: `make-bot-ui` and `automate-me` (Cursor-only), `setup-pstack` (this port reads `config/models.yml`), `typescript-best-practices` (the host has its own TypeScript standards), and `bro`. `statechart` and the two formal verification skills need Java and TLC on first run, installed via mise (or `TLA2TOOLS` and `JAVA` set).

Like the other forks, this port keeps `ponytail:` comments through every comment pass.

## Install

```bash
scripts/link-skills.sh          # symlink skills/ into ~/.pi/agent/skills
scripts/link-skills.sh --unlink # remove the links
scripts/link-skills.sh --root <dir>  # another skills root, e.g. a project's .pi/skills
```

The default root follows `PI_CODING_AGENT_DIR` when it is set. Pi discovers `<root>/<name>/SKILL.md` and follows symlinks, so an edit here lands in the catalog without reinstalling. A running session picks up a new skill name after `/reload`.

pi-subagents must be installed for the delegation steps (`pi install npm:pi-subagents`).

Validate before installing:

```bash
node scripts/check-skills.mjs
```

The checker validates frontmatter, names, references, and links, and fails on any term left over from another host's port (`~/.dsh`, `reasoning_effort`, `todo_write`, and so on).

## Use

Type `/skill:poteto-mode` or say "poteto" to enter the working style. From there the playbooks route by task:

| Task                               | Playbook                                                                                                                                            |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Read-only question                 | `skills/poteto-mode/playbooks/investigation.md`                                                                                                     |
| A reported defect                  | `skills/poteto-mode/playbooks/bug-fix.md`                                                                                                           |
| New behavior                       | `skills/poteto-mode/playbooks/feature.md`                                                                                                           |
| Behavior-preserving restructure    | `skills/poteto-mode/playbooks/refactoring.md`                                                                                                       |
| Work spanning phases or PRs        | `skills/poteto-mode/playbooks/multi-phase-plan.md`                                                                                                  |
| Pruning jj workspaces to free disk | `skills/poteto-mode/playbooks/worktree-cleanup.md` (tests: `bun test skills/poteto-mode/scripts/worktree-audit.test.ts`, which need `jj` on `PATH`) |
| Any of the above, at the end       | `skills/poteto-mode/playbooks/opening-a-pr.md`                                                                                                      |

The supporting skills are user-invocable in their own right: `how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, `reflect`, `unslop`, `no-comments`, `technical-writing`, `show-me-your-work`, `benchmark-checklist`.

## Catalog visibility

The repo holds 52 skills. The 24 `principle-*` skills keep `disable-model-invocation: true`, as upstream has them, and so do `statechart` and the two formal verification skills. Pi honors the flag: those 27 stay out of the skill catalog in the system prompt, so every request does not pay for their descriptions, and the model reads the leaf file when a trigger names one.

The other 25 task skills (poteto-mode, the routines such as how, why, recall, teach, tdd, and figure-it-out, and the writing and review passes) drop that flag, so the model can also route to them on its own when a task matches. Upstream relies on the user typing the command. On this host the model finding `bug-fix` by itself is worth 25 catalog entries.

## Model roles

Two layers pick models on this host, and they do not overlap.

- **The parent.** The session runs the virtual model `router/auto`, served by the Jev router extension in `~/.pi/agent/extensions/router`. Jev judges each user turn, sets the parent's thinking level, and picks the parent's model (peak-hour and hard-task routing). This repo does not touch it, and the skills tell the agent not to restate the parent's model or effort.
- **The children.** This repo's `config/models.yml` names a route per pstack role, and each `subagent` call passes it as `model: "<provider>/<model>:<effort>"`. A per-call model is the strongest layer in pi-subagents, so it wins over `subagents.agentOverrides`, agent frontmatter, `subagents.defaultModel`, and the parent's model. Nothing needs enabling.

The shipped defaults, all on the `commandcode` provider from `~/.pi/agent/models.json`:

| Role                                                                                   | Route                                             | Effort         |
| -------------------------------------------------------------------------------------- | ------------------------------------------------- | -------------- |
| `code`                                                                                 | `deepseek/deepseek-v4.1-flash`                    | max            |
| `prose`, `judgment`                                                                    | `xiaomi/mimo-v2.6-pro`                            | high           |
| `explorer`, `why_investigator`                                                         | `deepseek/deepseek-v4.1-flash`                    | high           |
| `explainer`, `architect`, `interrogate_lead`, `reflect_synthesizer`, `why_synthesizer` | `xiaomi/mimo-v2.6-pro`                            | high           |
| `arena` (2 seats)                                                                      | mimo-v2.6-pro, glm-5.3-flash                      | high, high     |
| `arena_judge`                                                                          | deepseek-v4.1-flash                               | max            |
| `interrogate_reviewers`, `reflect_lenses` (3 seats)                                    | mimo-v2.6-pro, glm-5.3-flash, deepseek-v4.1-flash | high, max, max |
| `swarm_workers`                                                                        | `deepseek/deepseek-v4.1-flash`                    | high           |
| fallback                                                                               | `deepseek/deepseek-v4.1-flash`                    | high           |

So the `code` role is passed as `model: "commandcode/deepseek/deepseek-v4.1-flash:max"`. Keep the provider prefix: the model ids contain `/`, so a bare id may not resolve to the intended provider.

Effort is set to each model's ceiling rather than one value across the board. MiMo V2.6 Pro stops at `high`, so an arena seat on MiMo cannot go deeper; the GLM seat is held at `high` as well so the two candidates are compared at the same depth. The review seats keep `max` on the models that accept it, because a review is a single diff read rather than a long loop.

Why these and not a premium reasoning model: subagents run an agent loop, so input volume dominates and a $2/$6 route costs roughly ten times a $0.15/$0.5 one. `z-ai/glm-5.3-flash` carries the highest measured intelligence of the cheap tier (57.5) and a different training lineage from MiMo and DeepSeek, which is the property the arena and the adversarial reviewers actually need. Diversity comes from the family, not the price tag.

Deliberately avoided: `xai/grok-4.7` at $2/$6 for no measured intelligence gain, and the `*-contributor` routes. Those are 95% cheaper but trade data contribution for the discount, which is the wrong deal for work that touches private repos.

To override a role without editing the repo, write `~/.pi/pstack-models.yml` with the same shape and only the roles you want to change. It wins over this file.

Check what the host actually resolves before trusting a route. `subagent({ action: "models" })` lists the registry ids, `/model` shows what the parent can select, and `/subagents-models` shows the live agent-to-model mapping. Two settings in `~/.pi/agent/settings.json` can refuse a route: an enforced `subagents.modelScope` aborts an explicit model outside its allow list, and `subagents.maxThinking` fails a request above its ceiling.

## Keeping up with upstream

The upstream is vendored as a snapshot for diffing:

```bash
scripts/sync-upstream.sh          # fetch cursor/plugins at main, refresh .upstream-snapshot
scripts/sync-upstream.sh --check  # report files that changed, change nothing
```

A sync does not rewrite the port. It tells you what moved, and you decide which ports to redo.

## Layout

```
skills/                    52 skills, one directory each, each with SKILL.md
  poteto-mode/             the working style
    playbooks/             one per kind of task
    scripts/check-plan.mjs validates a multi-phase plan
  how/ why/ architect/ …   supporting skills, some with references/
config/models.yml          role to route mapping
docs/harness/pi.md         the Cursor to Pi mapping
scripts/link-skills.sh     install into a Pi skills root
scripts/check-skills.mjs   validate skills and catch leftover host terms
scripts/sync-upstream.sh   diff against upstream pstack
```

## License and provenance

Ported from pstack (0.15.30 at the time of writing) by Lauren Tan, MIT licensed. The upstream LICENSE is in this repo. Skill text is derived from the upstream and rewritten for Pi by way of the DSH port; the changes are the mapping above, not the ideas. Anything wrong with the port is the port's fault, not upstream's.
