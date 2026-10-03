---
name: tdd
description: Use when I ask for tests first, TDD, or red-green-refactor.
---

1. Write one small failing test for the next behavior. Run it. Show it failing for the right reason.
2. Write the least code that makes it pass. Run it. Show it green.
3. Refactor only while green. Run the tests again.
4. Repeat, one behavior at a time. Build the code top-down: the most abstract piece first.
Never write the implementation before its test. Never change a test just to make it pass.
For Go: table-driven tests, `go test ./pkg/... -run TestName -v`.
