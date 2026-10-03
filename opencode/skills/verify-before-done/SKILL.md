---
name: verify-before-done
description: Use before saying a code change is finished. Builds, runs the relevant tests and checks diagnostics, then reports the real result.
---

Before you tell me a change is done:

1. Find how this repo builds and tests (Makefile, go.mod, package.json, pyproject.toml, README).
2. Build it. For Go: `go build ./...` and `go vet ./...` on the packages you touched.
3. Run the tests for the code you changed. For Go: `go test ./path/to/pkg/...`.
4. Read the LSP diagnostics for the files you edited.
5. Report what you ran and what happened, with the failing output if anything failed.
   Only say "done" when the build and the tests pass.
