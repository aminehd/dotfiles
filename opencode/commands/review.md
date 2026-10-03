---
description: Review my current changes for real bugs before I commit
agent: review
subtask: true
---
Review my uncommitted changes.

Files changed: !`git status --short`
Diff: !`git diff HEAD --stat`

$ARGUMENTS
