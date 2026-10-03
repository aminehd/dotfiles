# How to work with me

- Read the code around a change before editing it. Match its style, names and comment density.
- Never invent an API, flag, field or file. If you are not sure it exists, search for it first.
- Keep changes small and focused on what I asked. No drive-by refactors.
- After every change, build and run the tests that cover it. Read the errors yourself and fix them
  before you say you are done. Use the LSP diagnostics.
- If something fails and you cannot fix it, say so plainly with the error. Do not claim it works.
- Ask before anything hard to undo: deleting files, git push, force push, changing a cluster.
- Kubernetes: check the current context before any kubectl or helm command, and prefer read-only
  commands (get, describe, logs) unless I ask for a change.
- Explain in short, plain sentences. I like to see what the code does, step by step.
