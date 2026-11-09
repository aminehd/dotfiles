---
name: uml-render
description: Use when I ask for a UML, a class diagram or PlantUML. Draws it and renders a PNG on this machine.
---

Write to ~/uml/<name>.puml, never inside the repo.
Never use Kroki or any online renderer. Never put diagram text in a URL.
Read real signatures from the code. Don't guess. Max 15 classes, relevant methods only.

Render only with: ~/.config/opencode/skills/uml-render/render.sh ~/uml/<name>.puml
You are not done until it prints OK. Then give me the PNG path; don't try to display it.
If it fails, fix only the line it prints and run it again. Stop after 3 tries and show me the error and the file.

Syntax:
- Line 1 is @startuml, last line is @enduml. No markdown fences. No Mermaid (never classDiagram).
- Go types inside a class are fine: []byte, map[string]string, *Foo, struct{}
- Generics must be quoted: class "Box[T any]" as Box
- Never write "type Foo struct". Use class Foo.
- Arrows, only these: --> uses, ..|> implements, *-- contains
- Notes on one line: note right of A : text

Template:

@startuml
hide circle
hide empty members
class IThing <<interface>> {
  Create(uc, req) (string, *e.Error)
}
class thing {
  deps IDep
}
class IDep <<interface>>
thing ..|> IThing
thing --> IDep : uses
note right of thing : one line note
@enduml
