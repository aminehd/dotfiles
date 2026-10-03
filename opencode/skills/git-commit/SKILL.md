---
name: git-commit
description: Use when making a git commit or preparing a branch for review.
---

1. `git status` and `git diff --staged`. Check the branch: never commit straight to main/master
   unless I said so. Create a branch if needed.
2. Make sure no secrets, kubeconfigs, .env files or large generated files are staged.
3. Build and run the tests for what changed (see verify-before-done).
4. One logical change per commit. Message: a short imperative summary line (under 70 chars),
   a blank line, then why the change was needed, if not obvious.
5. No AI attribution and no Co-Authored-By trailers. The commit is mine.
6. Do not push. Tell me the commit is ready and I push it.
