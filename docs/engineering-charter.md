# Engineering Charter

**This document does not govern. It derives.**

The governing document is *The Center of Success Constitution, Version 1.0*, held in
the `Center of Success Constitutional System` folder in Drive, alongside the Canons
of Practice, Field Guide, Governance Charter, and CircleUp Formation Standard v1.0.

Article XVII establishes the ecosystem order and states that every framework, lesson,
practice, program, and artifact must serve the Constitution. Software is such an
artifact. This file exists only to translate the Constitution's articles into build
constraints that can be applied to a diff. Where this document and the Constitution
differ, **the Constitution is right and this file is a defect.**

Constitutional Director: Brian. Plural intelligence may explore, challenge, and
recommend; it does not replace human dignity, relational judgment, spiritual
discernment, or legitimate authority.

> **Constitutional test for this repository, per Article XVII:**
> Does this clarify, serve, train, or protect the Constitution?

---

## Derivations

Each constraint cites the article it serves. A constraint with no article is not a
constraint — it is a preference, and it does not belong here.

### From Article XIV — Dignity

> *No practice is faithful if it violates dignity.*

**C1. No shame mechanics.** No streak that resets, no loss framing for rest, no
"you broke your chain." Rhythm is measured so that rest counts as rhythm. A person
who practices four days a week for a year is succeeding, and the product must be
capable of saying so.

**C2. Character is never scored.** Metrics describe practice — loops closed,
follow-through kept, pressure examined before acting. No number may claim to describe
who a person is. Every metric must state what it measures and what it does not; if it
cannot, it does not ship.

*Enforced. See "What these numbers mean" on the Dashboard.*

### From Article IV — Trust, and Article III — Alignment

> *Trust = Integrity × Accountability. Integrity means Say → Do. Accountability
> means Did → Said.*

**C3. The Trust Loop is Say → Do → Did → Said**, and a miss that was truthfully
reported is accountability working, not failure. The schema counts
`missed_and_reported` toward trust; only `missed_silently` counts against it.

**C4. The alignment loop is longer than the trust loop** —
Story → Say → Do → Did → Said → Return (Article III). The product implements the
trust loop only. Story and Return are not yet modeled.

*C3 enforced in `db/001_schema.sql`. C4 outstanding.*

### From Article V — Respect, and Article VIII — The Compass

> *Without respect, courage becomes aggression. Without respect, generosity becomes
> depletion. Without respect, strength becomes control. Without respect, peace
> becomes avoidance.*
>
> *Constitutional test: Which virtue is needed, which virtue is being overused, and
> which virtue must be integrated?*

**C5. Overextension must be visible.** A Compass showing only virtues teaches half
the doctrine. Every virtue carries its overextension and the adjacent virtue that
corrects it. This has been taught in the field since November 2025.

*Enforced in the Compass.*

### From Article XI — Community

> *CircleUp is not merely a meeting. It is a formation rhythm.*

**C6. CircleUp follows the six movements** of CircleUp Formation Standard v1.0 —
Center, Surface, Name, Mirror, Practice, Return — each with its facilitator posture.
No invented session structure may stand in for the protocol practiced in the field.

*Enforced.*

### From Article XVI — Christ / The Center, and Article VI — Service

> *Every formation system has a center. The center names what is ultimate.*
> *At Symba, this formation serves the mission of Service.*

**C7. The center is tenant-scoped, and the system never manufactures one.** The Symba
instance is explicitly ordered: Christ is the ultimate Center, Service is the
governing mission. Another organization brings its own worthy commitments and the
system helps it embody them. A tenant that has not declared a center may not be
assigned one — a CHECK constraint, not a copy decision. Retrofitting is a rewrite.

*Enforced in `db/001_schema.sql`.*

### From Article XV — Drift

> *Drift is dangerous because it can look productive. The answer to drift is return.*

**C8. Growth tactics are drift.** Engagement maximization, variable reward,
artificial scarcity, and anxiety-driven notification are forbidden however standard
they are, because each looks productive while reordering the center.

**C9. Formation data is firewalled from employment decisions.** The first sincere
request this system will receive is to feed a performance review. Formation dies the
day practice becomes performance — people write theater and the circle is over.
Encoded as a CHECK constraint, so reversing it takes a migration and a conversation
rather than an admin toggle.

*Enforced in `db/001_schema.sql`.*

### From Article XIV — Dignity, applied to data

**C10. Non-extraction is structural or it is nothing.** Private by default. Export
and delete are first-class and require no one's permission. Sharing is explicit and
revocable. Aggregates too small to protect a person are withheld, not caveated.
Content is never mined for analytics, training, or marketing.

**C11. Reflection content is stored apart from participation facts**, so supervisory
and organizational views cannot reach content by join — not by policy, but because
the path does not exist.

*Enforced in app and schema.*

### From the care context — Articles XIV and VI

**C12. No person receiving care exists in this schema.** This system concerns the
practitioner's formation. Keeping resident detail out is what keeps these records
from becoming protected health information, and keeps a formation journal from
becoming discoverable in a licensing survey or in litigation.

**C13. Safety disclosures route out.** A formation journal must never absorb a
mandated report. The system records that a person was routed to the real channel,
never what they disclosed.

*Enforced in `db/001_schema.sql`.*

### From Article X — Practice, and the AI question

> *No Constitution forms people by being admired. Formation requires practice.*

**C14. AI is subordinate machinery.** Rafiki never renders moral verdict on a person,
never grades character, never substitutes for a conversation belonging to people with
real standing in someone's life, and never supplies values the person has not named.
It reflects, asks, surfaces contradictions, cites the framework, and returns judgment
to the human. Its instructions live in version control, reviewable by the
Constitutional Director.

*Enforced. See `rafiki-system-prompt.md`.*

---

## Known gaps

Written down so they are not mistaken for decisions.

| Gap | Article |
| --- | --- |
| Story and Return unmodeled; only the trust loop is implemented | III |
| CORE Work — the personal discipline — absent from the product | XII |
| Center Map, Four Directions, and the eight postures absent | XIII |
| Modes of Engagement absent | XVII |
| Facilitators and session debriefs not yet in the schema | XI |
| Seed data and invariant tests for the schema unwritten | — |

## Decisions reserved to the Constitutional Director

- Where the line sits between a facilitator seeing a member's reflections and a member's privacy
- Whether Rafiki reaches the whole cohort or facilitators first
- What evidence counts as the work being proven inside Symba
- Whether the general framework carries the Symba lineage visibly or is neutral at the surface
