# pstack in Pi

pstack skills use Cursor names. In Pi, read this file once per session, then map each Cursor name in a skill with the tables below. `<pstack>` means the folder that holds `skills/` and `docs/`. If a Cursor field has no row, drop it and say so. Never pass a field or an option that Pi does not accept.

Pi here is the pi.dev coding agent (`@earendil-works/pi-coding-agent`). Subagents come from the `pi-subagents` package. Its own reference is reachable in-session with `subagent({ action: "guide", options: { topic: "tool-reference" } })` (topics include `models` and `workflows`), and it wins over this file when the two disagree.

## Tool mapping

| Cursor                                | Pi                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Task` tool                           | `subagent` tool. A fresh session may expose only the `subagents_enable` loader; call `subagents_enable({})` once and `subagent` is available on the next request.                                                                                                                                                                                                                                                       |
| `subagent_type: generalPurpose`       | `agent: "delegate"`. The prompt you write in `task` is the role.                                                                                                                                                                                                                                                                                                                                                        |
| `subagent_type: "poteto-agent"`       | `agent: "delegate"`, with the delegation brief written by you in `task`.                                                                                                                                                                                                                                                                                                                                                |
| Other builtin roles                   | `scout`, `worker`, `reviewer`, and `oracle` exist but carry their own prompts, default reads, and output files. pstack briefs define the role themselves, so use `delegate` unless a skill names another agent.                                                                                                                                                                                                         |
| `readonly: true`                      | No field on `delegate`. State "this is read-only, do not edit files" in the task.                                                                                                                                                                                                                                                                                                                                       |
| `model`                               | `model: "<provider>/<model-id>:<effort>"` on the `subagent` call, for example `commandcode/deepseek/deepseek-v4.1-flash:max`. Always prefix the provider: these model ids contain `/` themselves. A separate `thinking` field is ignored on dispatch.                                                                                                                                                                   |
| Fork this conversation into the child | `options: { context: "fork" }`. The default is `fresh`. Use fork only when the child genuinely needs this context.                                                                                                                                                                                                                                                                                                      |
| `run_in_background: true`             | `async` is on by default. Pass `async: false` when you need the child's output before your next step. A background child notifies the parent when it finishes; `bg_wait({ id, stopOnAttention: false })` blocks until it does.                                                                                                                                                                                          |
| Several children at once              | One call: `subagent({ workflow: "parallel", args: { tasks: [{ agent, task, model? }, ...] } })`. Each item may carry its own `model`. The result lists each child's output in order. A workflow script with `runs.all` does the same when steps depend on each other. Workflows run in the background by default: when the next step reads the outputs, pass `async: false`, or `bg_wait` on the run id before reading. |
| `environment: "cloud"`                | No equivalent. Every child runs on this host.                                                                                                                                                                                                                                                                                                                                                                           |
| `Task` response body                  | The child's final message, returned by the tool or by the completion notice.                                                                                                                                                                                                                                                                                                                                            |
| Resume a child                        | `subagent({ action: "resume", id: "<run-id>", message: "..." })`. It starts a new child from the stored session, so the child keeps its transcript, model, and tools.                                                                                                                                                                                                                                                   |
| `TodoWrite`                           | No todo tool in Pi's core set (`read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`). Keep the list as a markdown checklist in your reply and re-post it when an item changes state.                                                                                                                                                                                                                                   |
| `AskQuestion`                         | No question tool. Ask in the reply as a short numbered list of options and stop the turn.                                                                                                                                                                                                                                                                                                                               |

## Model roles

Cursor reads role models from a `pstack-models.mdc` rule. Pi reads them from `config/models.yml` in this repo, with a per-user override at `~/.pi/pstack-models.yml`. Both use the same role names. See `config/models.yml` for the shipped defaults and the resolution order.

A role entry is `provider`, `model`, and an optional `effort`. Join them into one string, `<provider>/<model>:<effort>`, and pass that as the `subagent` call's `model`. `subagent({ action: "models" })` lists the ids the registry resolves, and `/subagents-models` shows the live agent-to-model mapping.

A `model` passed on a call wins over every settings default (`subagents.agentOverrides`, agent frontmatter, `subagents.defaultModel`, the parent model). An unknown or ambiguous id fails before launch with the closest matches. If `subagents.modelScope` is enforced in `~/.pi/agent/settings.json`, an explicit model outside its allow list aborts the run. In either case, implementation work moves down the ladder in `config/models.yml`; other work uses the role's default. Say so in the reply either way. Each launch resolves one model; Pi does not fall back to another model on a provider error, so moving down the ladder means issuing the call again on the next seat.

Families in the upstream fallback rules map by prefix: a `claude-*` entry needs a Claude route on a registered provider, a `grok-*` entry needs an `xai/*` route, and so on.

## Effort

Effort travels as the `:level` suffix on `model`. Pi's levels are `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, and `max`. `subagents.maxThinking`, when set, is a hard ceiling: a request above it fails before the child starts. The models themselves accept fewer levels, and the ceiling differs by family, so a panel that mixes families has to normalize:

| Model                          | Efforts           |
| ------------------------------ | ----------------- |
| `minimax/minimax-m3.1-flash` | low, medium, high, xhigh, max |
| `deepseek/deepseek-v4.1-flash` | low, high, max    |
| `z-ai/glm-5.3-flash`           | low, high, max    |
| `xiaomi/mimo-v2.6-pro`         | low, medium, high |
| `xiaomi/mimo-v2.6-flash`       | low, medium, high |

The parent session runs Xiaomi MiMo V2.6 Pro (`commandcode/xiaomi/mimo-v2.6-pro`) directly at thinking level high; it is the configured default model and never changes mid-session. A per-turn effort router (the Jev router extension, which exposed the virtual model `router/auto`, judged each user turn, and lifted the effort per model) was retired on 2026-11-01: the role table already fixes each seat's model and effort, so nothing routes the parent anymore. The separate jev-compaction and jev-pruner extensions remain installed. Child effort is set by the role table.

## Control skills

Cursor's `control-ui` and `control-cli` from `cursor-team-kit` are not available. Map by surface:

| Surface       | Pi substitute                                                                   |
| ------------- | ------------------------------------------------------------------------------- |
| Web UI        | the `web-verify` skill (Playwright screenshots plus console and network errors) |
| CLI or TUI    | run the real binary and capture its output; no wrapper skill                    |
| Recorded demo | the `readme-demo` or `web-demo-video` skill                                     |

Where a skill says a surface with no control skill is a risk, check that skill's own risk section.

## Commands

| Cursor command       | Pi                                                                                                                                                                                                         |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/deslop`            | Fold into the `unslop` skill pass over the diff before commit.                                                                                                                                             |
| `/no-comments`       | Fold into the `Comments` section of `poteto-mode` and the `no-comments` skill when it is installed.                                                                                                        |
| `/technical-writing` | The `technical-writing` skill.                                                                                                                                                                             |
| `/<skill>`           | `/skill:<name>`, for example `/skill:poteto-mode`.                                                                                                                                                         |
| `/loop 1h`           | `subagent({ action: "schedule.create", workflow: true, options: { every: "1h" } })`, with the tick written as a ` ```js workflow ` block in the same reply. A schedule runs a workflow, not a bare prompt. |

## Version control

Cursor skills assume `git` and `git worktree`. Every repo on this host is a colocated jj repo.

| Cursor                             | Pi                                                          |
| ---------------------------------- | ----------------------------------------------------------- |
| `git worktree add`                 | `jj workspace add <path>`                                   |
| `git reset --hard origin/<branch>` | `jj git fetch` then `jj new <bookmark>@origin`              |
| `git commit`                       | `jj commit -m "..."`                                        |
| squash / reorder into a stack      | `jj squash`, `jj split`, `jj rebase`                        |
| push                               | `jj bookmark set <name> -r @-` then `jj git push -b <name>` |
| `git show origin/main:<path>`      | `jj file show -r <bookmark>@origin <path>`                  |

Never run a git write command. Read-only `git` and `gh` are fine, and `gh` stays the forge CLI. pi-subagents' own `worktree` isolation needs a git worktree; prefer a `jj workspace add` path passed as `cwd`.

## Skills

| Cursor                                               | Pi                                                                                                                                                                                                                                                                                                                                               |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `.cursor/rules` always-applied rule                  | `~/.pi/agent/AGENTS.md`, or the project's `AGENTS.md`                                                                                                                                                                                                                                                                                            |
| skill `icon` / `color` fields                        | dropped                                                                                                                                                                                                                                                                                                                                          |
| `disable-model-invocation: true`                     | keep it for the `principle-*` skills, `statechart`, and the two formal verification skills. Pi honors it: the skill stays out of the catalog in the system prompt, so every request does not pay for 27 descriptions, and the model reads the leaf file directly. The other task skills drop it, so the model can also route to them on its own. |
| relative reference to a sibling skill                | an absolute path, because a subagent's working directory may differ and the builtin `delegate` does not inherit the parent's skills                                                                                                                                                                                                              |
| `references/*.md`                                    | the same relative path from the skill folder                                                                                                                                                                                                                                                                                                     |
| `.cursor/skills/<name>/` (a generated project skill) | `~/.pi/agent/skills/<name>/`, or `.pi/skills/<name>/` in the project. Pi discovers `SKILL.md` under either root and follows symlinks.                                                                                                                                                                                                            |
| `/setup-pstack`, the `pstack-models.mdc` rule        | `config/models.yml` and `~/.pi/pstack-models.yml`. See Model roles.                                                                                                                                                                                                                                                                              |

## Transcripts and memory

| Cursor                                                        | Pi                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.pi/agent/sessions/<slug>/<timestamp>_<session-id>.jsonl`, one plain JSONL file per session. The slug is the workspace path with the leading `/` dropped, every `/` (and `:`) turned into `-`, and wrapped in `--`, so `/home/pi` is `--home-pi--`. `PI_CODING_AGENT_DIR` moves the `~/.pi/agent` root. Subagent artifacts sit beside them under `subagent-artifacts/`. Read only this workspace's folder. |
| Past sessions and decisions (`recall`, `why`, session pickup) | Search the shared memmini memory first with Pi's native `memory_search`, using the user's wording, then read transcripts for what it misses. memmini is a lead, not a citation: check a hit against the code or the history before you rely on it.                                                                                                                                                            |

## Local equivalents

| Cursor                              | Pi                                                                                                                                        |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Bugbot or an agentic review pass    | The `interrogate` skill.                                                                                                                  |
| Cursor cloud agent, its own machine | No equivalent. Every child runs on this host. Skip a step that needs one, and say so.                                                     |
| `/create-skill`                     | Write `~/.pi/agent/skills/<name>/SKILL.md` directly, then run `node <pstack>/scripts/check-skills.mjs` when the skill lives in this repo. |

## Comments

Code on this host is also written by agents running the ponytail working style, which marks a deliberate shortcut with a `ponytail:` comment that names its ceiling and upgrade path. Those comments are load-bearing. Every comment pass, including `no-comments`, keeps them.
