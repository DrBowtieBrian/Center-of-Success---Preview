# Center of Success — Premium App Preview

A working, interactive preview of the **Center of Success** character operating system,
built to the direction set by the brand vision board: deep forest and gold, serif display
type, parchment surfaces, and a mobile-first structure.

**Open `index.html` in any browser.** No build step, no dependencies, no network calls.
On desktop it renders inside a device frame with the brand rail; on a phone it fills the screen.

---

## Read this first

[**`docs/CONSTITUTION.md`**](docs/CONSTITUTION.md) is the governing document. The vision,
the convictions, and the build constraints that follow from them — including what this
system will not ship, however standard it is elsewhere. Every decision here derives from it.

[**`docs/rafiki-system-prompt.md`**](docs/rafiki-system-prompt.md) is Rafiki's governed
system prompt, written to that constitution and ready to drop into an API call, with the
test cases it has to pass first.

Three constraints are already load-bearing in the code, not just described:

- **No streak.** Rhythm is measured in a way that counts rest as rhythm. A mechanic that
  punishes a day off contradicts the teaching.
- **Practice is measured; character is not.** Every metric can state what it measures and
  what it does not — see "What these numbers mean" on the Dashboard.
- **Non-extraction is structural.** Export everything and delete everything are real
  mechanisms in the menu, not promises in a policy.

## What's in the preview

Five tabs, matching the five pillars — SOIL, Trust Loop, CircleUp, Academy, Rafiki.

| Area | What actually works |
| --- | --- |
| **Today** | Time-aware greeting, Today's Center list, live streak + alignment, recent journal entries |
| **SOIL Check** | Full 4-question urgency diagnostic → scored result (Rightful Urgency / Unclear Ownership / Unnecessary Urgency) with root cause, pattern, risk, and faithful response |
| **Restoration Path** | STOP · SEE · OWN · REPAIR · SOW, reachable from the result or the menu |
| **Trust Loop** | Four-step SAY → DO → DID → SAID flow with a live loop diagram; writes a real journal entry and moves your skill scores |
| **Dashboard** | Loops closed vs. last week, alignment score, unnecessary urgency caught, rhythm kept — all computed from your actual activity, plus the Six Center Skills and derived "patterns to watch" |
| **Journal** | Searchable and filterable, with entry detail and free-form new entries |
| **CircleUp** | Circles, upcoming sessions, session structure, commit flow |
| **Academy** | Learning paths, the Six Keys with full keychains (SPEAK, LISTEN, POWER, LINK, TEAM, GEAR, STEP), LevelUp virtues, and the glossary |
| **Rafiki** | Assistant sheet that answers from your real data (scripted in this preview) |

State persists in `localStorage`. **Menu → Reset preview data** restores the seeded demo.

The full framework content — Six Keys, keychains, virtues, glossary — carried over from the
earlier preview, which is kept at `legacy/framework-preview.html`.

---

## What is deliberately still a preview

Honest list, so nothing here reads as further along than it is:

- **Rafiki is scripted**, not model-backed. It pattern-matches your question and answers from
  your local metrics. Real guidance needs an API call and a system prompt built on the canon.
- **CircleUp is single-player.** The rooms, sessions, and commitments render, but nothing is shared.
- **Lessons don't play.** Paths and progress are real UI; there's no lesson content behind them.
- **No accounts, no sync, no backend.** Everything lives in one browser.
- **Scores move on simple rules**, not on any assessment of what you actually wrote.

---

## Getting from here to a shipped premium app

**1. Content before code.** The system's value is the canon — scenarios, lesson scripts,
diagnostic copy. That's the long pole and it doesn't require engineering to start.

**2. Make Rafiki real.** Highest-leverage single change. A Claude API call with the Center of
Success framework as its system prompt turns every screen from static to responsive: SOIL Checks
get a genuine diagnosis of the situation you describe, Trust Loop entries get formative feedback,
the dashboard gets narrative insight instead of derived numbers. Needs a thin backend to hold the key.

**3. Accounts and sync.** Auth plus a hosted database, so the journal survives a lost phone
and a person's formation history is actually theirs. This is the gate for everything social.

**4. Native shell.** This codebase moves to React Native / Expo cleanly — the design system
translates directly. That unlocks push notifications, which is what makes a daily practice
habit actually daily.

**5. CircleUp for teams.** Shared rooms, private-until-submitted contributions, aggregate
patterns without exposing individual confessions. This is the team tier and the business model.

**6. Organizational insight.** Anonymized trust and alignment patterns across a company —
the CenterOS layer the vision board points at.

Steps 1–2 are worth doing next; they change the product's nature more than the rest combined.

---

## Design system

| Token | Value | Use |
| --- | --- | --- |
| Forest | `#1B2A1F` | Deep ground, dark surfaces |
| Moss | `#4A5A40` | Primary action, active state |
| Gold | `#B8892B` | Accent, progress, emphasis |
| Tan | `#C58B4A` | Warm secondary |
| Clay | `#8C3B2E` | Routes, alerts |
| Parchment | `#FAF7F0` | App background |
| Paper | `#FFFDF8` | Cards |

Display type is a serif stack (Iowan Old Style → Palatino → Georgia); body is the system UI stack.
Icons are a single inline SVG set — no icon font, no external requests.
Honors `prefers-reduced-motion`.
