# agent

My coding-agent setup: four harnesses and a multi-agent runner, sharing one set of
rules and skills.

```text
agent/
  AGENTS.md     how to work with me        -> opencode, pi, omp (paste into Cursor's User Rules)
  skills/       shared SKILL.md folders    -> ~/.agents/skills, ~/.cursor/skills
  opencode/     agents, commands, rtk plugin, permissions, theme
  cursor/       rtk hook, MCP servers
  install.sh    installs the harnesses and makes the links
```

| Tool | What it is | When I use it |
|---|---|---|
| **opencode 2** | Full harness: terminal, desktop app, agents, commands, plugins | Daily driver, it has all my agents and commands |
| **pi** | Small, fast harness you extend with packages | Quick tasks; subagents through `pi-subagents` |
| **omp** (oh-my-pi) | pi with batteries: built-in subagents, compaction tuning | Bigger tasks that need scout → task → reviewer |
| **herdr** | Terminal multiplexer that knows agent state | Running several harness sessions side by side, and letting one agent drive the others |
| **Cursor** | IDE | When I want to click through code |

All of them talk to one model provider, set up per machine (step 2). The repo has
no provider names, URLs or keys.

## Ramp-up on a new machine

**1. Remove opencode 1** (two `opencode` commands confuse everything):

```sh
which -a opencode          # every copy on PATH
opencode --version         # 1.x means the old one
```

Uninstall it the way it was installed. `agent/install.sh` copies the old sessions to
`~/.local/share/opencode-v1-backup` first if it finds opencode 1, so run step 3 once
before uninstalling if you care about them.

**2. Provider and key: this is when you copy your token.**
Get a fresh API key from the provider's key page, then paste it in exactly one place:

```sh
nvim ~/.secrets.zsh        # export WORK_LLM_API_KEY=...   (file is chmod 600, not in git)
source ~/.secrets.zsh
```

Then write each harness's provider file from the provider's own install guide, using
the env var instead of pasting the key again:

| Harness | Machine-only file | Key goes in as |
|---|---|---|
| opencode | `~/.config/opencode/opencode.jsonc` | `"apiKey": "{env:WORK_LLM_API_KEY}"` |
| pi | `~/.pi/agent/models.json` | the variable name `WORK_LLM_API_KEY` |
| omp | `~/.omp/agent/models.yml` | the variable name `WORK_LLM_API_KEY` |

Desktop apps don't read `~/.secrets.zsh`. For those, use a key file (`chmod 600`) as the
guide says.

**3. Install and link:**

```sh
cd ~/dotfiles && git pull && ./agent/install.sh
```

The last lines say which provider files are still missing.

**4. Verify, one by one:**

```sh
opencode models | grep work          # your provider's models are listed
opencode run "Say hello"
pi --list-models                     # then: pi -p "Say hello"
omp models refresh && omp -p "Say hello"
herdr                                # opens; start a harness in a pane
```

Inside a session: opencode `/skills` (or ask "what skills do you have"), pi
`/subagents-doctor`, omp `/agents`. Each should list the shared skills.

**5. Old sessions:** `opencode session list` in 2. If the old ones aren't there, they
are still in `~/.local/share/opencode-v1-backup`. Copy out what you need, as text.

## Multi-agent, in three levels

### Level 1: subagents inside one session

The main agent hands a task to a helper with a **fresh, empty context**. The helper
reads 40 files; you get back 5 lines. Your main context stays small.

```text
you ─► main agent ─► scout   (read-only: "where is X wired?")   ─► 5-line answer
                  └► reviewer (read-only: "review this diff")    ─► findings
```

| Job | opencode | pi | omp |
|---|---|---|---|
| Map code, find things | `explore` | `scout` | `scout` |
| Implement | main agent | `worker` | `task` |
| Review | `/review`, `review` agent | `reviewer` | `reviewer` |

Just ask in plain words: *"Use scout to find where the policy repository is
registered."*, *"Run two reviewers in parallel: one for correctness, one for missing tests."*

### Level 2: several sessions side by side (herdr)

A subagent dies with its parent and only reports at the end. A herdr pane is a full
harness session: it keeps running if you close the terminal, you can watch it, and you
can type into it mid-task.

```sh
herdr                                         # once; start your harness in a pane

# open a pane on the right, keep your focus here
herdr pane split --current --direction right --cwd "$PWD" --no-focus
# start a pi agent in it, give it a task, wait, read the answer
herdr agent start reviewer --kind pi --pane <PANE_ID>
herdr agent prompt reviewer "Review internal/service for bugs. Don't edit files. file:line, one sentence each." --wait --timeout 300000
herdr agent read reviewer --source recent-unwrapped --lines 120
herdr agent list                               # who's working, blocked or idle
```

`herdr agent get <name>`: if it says **blocked**, it's waiting for an answer or an
approval. Read it and answer before prompting again.

### Level 3: one agent drives the others

Install herdr's skill into your harness, then talk to your main agent like a lead:

> Use herdr to start two pi agents next to you. One lists the bugs in
> `internal/service/policy.go` as file:line plus one sentence. The other lists the 5 most
> important missing tests. Neither edits files. Wait for both, then merge and drop duplicates.

> Use herdr to have a pi agent fix the failing test in `policy_test.go`. When it's done,
> review its diff and run the tests yourself. If anything fails, send it back with the
> failure, at most twice.

### The rules that make it work

- **Delegate only when it pays.** Big research, parallel independent tasks, or a fresh
  pair of eyes. Small steps are faster in one session.
- **Split by context, not by job title.** Each helper should need little from the rest.
- **Brief it like a new colleague:** goal, files, constraints, what to report back.
- **Ask for proof**, not "done": test output, file:line.
- **One writer per repo.** Readers in parallel are fine.
- **Review with a fresh agent**, and check the claims it makes before acting.
- **Watch the cost.** Every herdr worker is a full session that spends its own tokens.

## Quiz yourself

1. You want "where is the restore flow for MCP servers?" answered without filling your
   context. Which level, and which agent in omp?
2. A reviewer in a herdr pane shows **blocked**. What do you do first?
3. Why "one writer per repo"?
4. Where does your API key live, and why is it not in this repo?

## opencode details

- `config.json` (loaded through `OPENCODE_CONFIG` in zshrc, merged on top of the
  machine's own `opencode.jsonc`): LSP on, asks before kubectl apply/delete/edit/scale/patch,
  helm install/upgrade/uninstall, git commit/push, `rm -r`. The `ask` rules are listed
  twice, with and without `rtk `, because the rtk plugin rewrites the command first.
  Hides opencode 2's bundled free models (`experimental.policies`). MCP servers are
  set up but off until MCP is allowed (`WITH_MCP=1 ../install.sh` installs Serena).
- npm plugins: `@tarquinen/opencode-dcp` drops old tool output, `opencode-pty` drives a
  REPL (`yaegi`, `python3 -i`).
- agents (Tab to switch): `k8s`, `teach`, `review`, `explore` (set a fast `model:` for it in
  the machine's `opencode.jsonc`, `agent.explore.model`).
- commands: `/kstatus`, `/kwhy`, `/kwho`, `/explain`, `/chart`, `/review`, `/commit`, `/quiz`.
- `tui.json`: tokyonight, smooth scrolling. `ctrl+x b` toggles the sidebar.

## Cursor details

- `hooks.json`: shell commands go through rtk, like the opencode plugin.
- `mcp.json`: context7 and Serena, linked only with `WITH_MCP=1`.
- `~/.cursor/skills` is the shared `skills/` folder.
- `cursorignore`: copy into a repo as `.cursorignore`, or paste into Settings → Indexing &
  Docs → Global Cursor Ignore.
- User rules aren't files in Cursor: paste `AGENTS.md` into Settings → Rules → User Rules.
