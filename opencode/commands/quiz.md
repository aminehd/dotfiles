---
description: Quiz me on code or my current diff before explaining it. Usage: /quiz [thing]
agent: teach
---
Quiz me on $ARGUMENTS. If that is empty, use my current `git diff`.

Ask 3 short questions, one at a time, easiest first, about what the code does and why it has this shape.
Use real names from the code. No syntax trivia. Wait for my answer after each one.
If I'm right, say so in a few words. If I'm wrong, give the smallest hint and let me try once more.
Only then explain it top-down, with a tiny diagram if it helps. Never give the answer before I've tried.
