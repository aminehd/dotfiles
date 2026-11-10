---
name: debug-systematically
description: Use for any bug, test failure or unexpected behavior, before proposing a fix.
---

1. Reproduce it. Write down the exact command and the exact wrong output.
2. Read the full error and stack trace. Find the first line that is our code.
3. Make one hypothesis that explains all the evidence. Say it out loud.
4. Test the hypothesis with the smallest check: a print, a log line, a debugger breakpoint,
   a unit test. Change one thing at a time.
5. If it is wrong, drop it and form a new one from the new evidence. No guess-and-check edits.
6. Fix the cause, not the symptom. Add a test that failed before the fix and passes after.
7. Re-run the original reproduction to confirm.
