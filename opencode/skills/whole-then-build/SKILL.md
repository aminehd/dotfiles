---
name: whole-then-build
description: Use when I give you a whole design to build as one change, or when a new entity should copy an existing one.
---

1. Read the whole design before doing anything. Make no edits yet.
2. Find the closest existing thing in the repo to copy. Search with `rg -n`, read only the lines you need.
3. Give me one table: each file, new or edit, the existing file:line it copies, and anything that doesn't fit the repo.
4. Say in one line what you are deliberately leaving out.
5. Stop and wait for me to say "go".
6. After "go", write all the files in one pass. Touch only the files in the table. If the repo conflicts with my design, follow the repo and tell me.
7. Load verify-before-done, then show `git diff --stat` and the results. Do not commit until I say "push".
