-- =============================================================================
-- Center of Success — core schema
-- Target: PostgreSQL 15+
--
-- Derived from docs/CONSTITUTION.md. Where a constraint could be either policy
-- or structure, it is structure. Comments cite the article they enforce.
--
-- Context: a care organization (residential, health, and community services).
-- The people using this are direct support professionals, case managers,
-- nurses, coordinators, clinicians, and directors. That context drives four
-- design decisions that would otherwise look like over-engineering:
--
--   1. Reflection content is stored apart from participation facts, so that
--      supervisory and organizational views CANNOT reach content by join.
--   2. There are no fields for the people receiving care. This system is about
--      the practitioner's formation. Keeping resident detail out is what keeps
--      these records from becoming PHI.
--   3. Practice data is firewalled from employment decisions, and every read of
--      content is logged, because the first sincere request this system will
--      receive is to feed a performance review.
--   4. Safety disclosures are routed OUT of this system to the real reporting
--      channel. A formation journal must never become a shadow incident report.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- Tenancy and values
-- Constitution §4 — values are pluggable and the system never manufactures them.
-- This is a schema-level decision on purpose: retrofitting it is a rewrite.
-- -----------------------------------------------------------------------------

CREATE TYPE values_mode AS ENUM (
  'declared',   -- the organization has named its own commitments
  'lineage',    -- the organization adopts the Symba lineage explicitly
  'none'        -- no values layer; the framework runs value-neutral at the surface
);

CREATE TABLE tenant (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug              text NOT NULL UNIQUE,
  name              text NOT NULL,
  values_mode       values_mode NOT NULL DEFAULT 'none',
  -- Populated only for 'lineage'. Symba's center is explicit; no other tenant
  -- inherits it by default, and none can be assigned it implicitly.
  governing_mission text,
  ultimate_center   text,
  min_aggregate_n   int NOT NULL DEFAULT 5,   -- k-anonymity floor, §2
  created_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT lineage_declares_center CHECK (
    values_mode <> 'lineage' OR (governing_mission IS NOT NULL AND ultimate_center IS NOT NULL)
  ),
  -- A tenant that is not lineage may not carry an ultimate center. This is the
  -- structural half of "the system does not manufacture values."
  CONSTRAINT no_imposed_center CHECK (
    values_mode = 'lineage' OR ultimate_center IS NULL
  ),
  CONSTRAINT aggregate_floor_sane CHECK (min_aggregate_n >= 3)
);

CREATE TABLE tenant_commitment (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  name        text NOT NULL,
  description text,
  ordinal     int  NOT NULL DEFAULT 0,
  UNIQUE (tenant_id, name)
);

-- -----------------------------------------------------------------------------
-- People and care roles
-- No resident/patient entity exists anywhere in this schema. That absence is
-- deliberate and load-bearing: it is what keeps this out of PHI territory.
-- -----------------------------------------------------------------------------

CREATE TYPE care_role AS ENUM (
  'direct_support_professional',
  'residential_coordinator',
  'case_manager',
  'nurse',
  'behavioral_health_clinician',
  'program_director',
  'executive_leadership',
  'administrative'
);

CREATE TABLE person (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  display_name  text NOT NULL,
  email         citext,
  primary_role  care_role NOT NULL,
  hired_on      date,
  -- Set when a person exercises deletion. Their content is destroyed; this row
  -- persists only so historical aggregates do not silently change shape. §2
  erased_at     timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, email)
);
CREATE INDEX person_tenant_idx ON person (tenant_id) WHERE erased_at IS NULL;

-- -----------------------------------------------------------------------------
-- Cohorts and circles
-- Cohort-first from the start: Constitution §6, prove inside Symba, and
-- retrofitting groups onto a single-player product is a rewrite.
-- -----------------------------------------------------------------------------

CREATE TABLE cohort (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  name        text NOT NULL,
  started_on  date NOT NULL,
  ended_on    date,
  CONSTRAINT cohort_dates CHECK (ended_on IS NULL OR ended_on >= started_on)
);

CREATE TYPE cohort_standing AS ENUM ('member', 'facilitator');

CREATE TABLE cohort_member (
  cohort_id  uuid NOT NULL REFERENCES cohort(id) ON DELETE CASCADE,
  person_id  uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  standing   cohort_standing NOT NULL DEFAULT 'member',
  joined_on  date NOT NULL,
  left_on    date,
  PRIMARY KEY (cohort_id, person_id)
);

CREATE TABLE circle (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  cohort_id   uuid REFERENCES cohort(id) ON DELETE SET NULL,
  name        text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE circle_member (
  circle_id uuid NOT NULL REFERENCES circle(id) ON DELETE CASCADE,
  person_id uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  PRIMARY KEY (circle_id, person_id)
);

-- -----------------------------------------------------------------------------
-- Practice: participation is separated from content
--
-- THE central structural decision. `practice_session` records THAT a practice
-- happened and its non-sensitive shape. `practice_content` holds what the person
-- actually wrote, in a different table, reachable only through an access path
-- that logs. Dashboards, retention reporting, and circle aggregates read
-- sessions and never need content — so they cannot leak it, even by mistake,
-- even by a future engineer who does not know the rules. §2
-- -----------------------------------------------------------------------------

CREATE TYPE practice_kind AS ENUM ('soil_check', 'trust_loop', 'reflection', 'circle_session');

CREATE TABLE practice_session (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  person_id    uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  cohort_id    uuid REFERENCES cohort(id) ON DELETE SET NULL,
  kind         practice_kind NOT NULL,
  occurred_at  timestamptz NOT NULL,
  -- Minutes engaged. Never used to compare people. §5
  duration_min int,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX practice_person_time_idx ON practice_session (person_id, occurred_at DESC);
CREATE INDEX practice_tenant_time_idx ON practice_session (tenant_id, occurred_at DESC);

CREATE TABLE practice_content (
  session_id  uuid PRIMARY KEY REFERENCES practice_session(id) ON DELETE CASCADE,
  -- What the person wrote. Private to them by default; §2.
  body        text NOT NULL,
  -- Set when the person deletes. The session row survives for aggregates;
  -- the writing does not survive at all.
  erased_at   timestamptz,
  CONSTRAINT erased_is_empty CHECK (erased_at IS NULL OR body = '')
);

-- -----------------------------------------------------------------------------
-- SOIL Check — structured diagnostic, safe to aggregate
-- The answers are ordinal codes, not prose, which is why organizational
-- pattern-finding can run entirely without touching anyone's writing.
-- -----------------------------------------------------------------------------

CREATE TYPE urgency_diagnosis AS ENUM ('rightful', 'unclear_ownership', 'unnecessary');

-- The pressure context, by ROLE and SITUATION TYPE — never by person served.
CREATE TYPE pressure_context AS ENUM (
  'shift_coverage', 'documentation_deadline', 'family_or_guardian',
  'supervisor_request', 'regulatory_survey', 'peer_conflict',
  'behavioral_escalation', 'medication_process', 'personal_capacity', 'other'
);

CREATE TABLE soil_check (
  session_id      uuid PRIMARY KEY REFERENCES practice_session(id) ON DELETE CASCADE,
  is_real         smallint NOT NULL CHECK (is_real       BETWEEN 0 AND 2),
  whose_is_it     smallint NOT NULL CHECK (whose_is_it   BETWEEN 0 AND 2),
  what_beneath    smallint NOT NULL CHECK (what_beneath  BETWEEN 0 AND 2),
  cost_to_respond smallint NOT NULL CHECK (cost_to_respond BETWEEN 0 AND 2),
  diagnosis       urgency_diagnosis NOT NULL,
  context         pressure_context NOT NULL DEFAULT 'other'
);

-- -----------------------------------------------------------------------------
-- Trust Loop and commitments
-- Trust = Integrity × Accountability. Integrity is Say → Do; accountability is
-- Did → Said. A commitment makes the loop durable enough to actually measure.
-- -----------------------------------------------------------------------------

CREATE TABLE trust_loop (
  session_id   uuid PRIMARY KEY REFERENCES practice_session(id) ON DELETE CASCADE,
  opened_at    timestamptz NOT NULL,
  closed_at    timestamptz,
  CONSTRAINT loop_closes_after_open CHECK (closed_at IS NULL OR closed_at >= opened_at)
);

CREATE TYPE commitment_state AS ENUM ('open', 'kept', 'renegotiated', 'missed_and_reported', 'missed_silently');

CREATE TABLE commitment (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  person_id    uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  session_id   uuid REFERENCES practice_session(id) ON DELETE SET NULL,
  -- The commitment text is content. It lives here rather than in
  -- practice_content because a person may choose to share a commitment with a
  -- circle while keeping the reflection that produced it private. Sharing is
  -- still explicit: see share_grant.
  summary      text NOT NULL,
  made_at      timestamptz NOT NULL,
  due_at       timestamptz,
  state        commitment_state NOT NULL DEFAULT 'open',
  resolved_at  timestamptz,
  CONSTRAINT resolved_when_not_open CHECK (
    (state = 'open' AND resolved_at IS NULL) OR (state <> 'open' AND resolved_at IS NOT NULL)
  )
);
CREATE INDEX commitment_person_idx ON commitment (person_id, made_at DESC);

-- -----------------------------------------------------------------------------
-- Sharing — explicit, scoped, and revocable
-- Constitution §2: nothing a person wrote is shared without an explicit,
-- revocable act. Revocation is a timestamp, not a delete, so that an audit can
-- always answer "who could see this, and when."
-- -----------------------------------------------------------------------------

CREATE TYPE shareable AS ENUM ('practice_content', 'commitment');
CREATE TYPE audience  AS ENUM ('person', 'circle', 'cohort_facilitators');

CREATE TABLE share_grant (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  granted_by     uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  object_type    shareable NOT NULL,
  object_id      uuid NOT NULL,
  audience_type  audience NOT NULL,
  audience_id    uuid,        -- person id or circle id; null for cohort_facilitators
  granted_at     timestamptz NOT NULL DEFAULT now(),
  revoked_at     timestamptz,
  CONSTRAINT revoked_after_granted CHECK (revoked_at IS NULL OR revoked_at >= granted_at),
  CONSTRAINT audience_target_present CHECK (
    (audience_type = 'cohort_facilitators' AND audience_id IS NULL) OR
    (audience_type <> 'cohort_facilitators' AND audience_id IS NOT NULL)
  )
);
CREATE INDEX share_active_idx ON share_grant (object_type, object_id) WHERE revoked_at IS NULL;

-- -----------------------------------------------------------------------------
-- Access logging
-- Every read of another person's content is recorded. This exists so that the
-- promise "your supervisor is not reading your journal" is auditable rather
-- than merely asserted. §2, §3
-- -----------------------------------------------------------------------------

CREATE TABLE content_access_log (
  id           bigserial PRIMARY KEY,
  tenant_id    uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  actor_id     uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  object_type  shareable NOT NULL,
  object_id    uuid NOT NULL,
  share_id     uuid REFERENCES share_grant(id) ON DELETE SET NULL,
  accessed_at  timestamptz NOT NULL DEFAULT now(),
  purpose      text NOT NULL
);
CREATE INDEX access_actor_idx ON content_access_log (actor_id, accessed_at DESC);

-- -----------------------------------------------------------------------------
-- Employment firewall
-- The first sincere request this system receives will be to feed a performance
-- review. This table exists so the answer is a recorded institutional
-- commitment rather than one engineer's judgment on one afternoon.
-- -----------------------------------------------------------------------------

CREATE TABLE employment_use_policy (
  tenant_id            uuid PRIMARY KEY REFERENCES tenant(id) ON DELETE CASCADE,
  practice_data_in_hr  boolean NOT NULL DEFAULT false,
  ratified_by          text NOT NULL,
  ratified_at          timestamptz NOT NULL DEFAULT now(),
  -- Formation dies the day practice becomes performance. If a tenant ever wants
  -- this true, it takes a schema migration and a conversation, not a settings
  -- toggle in an admin panel.
  CONSTRAINT practice_data_never_in_hr CHECK (practice_data_in_hr = false)
);

-- -----------------------------------------------------------------------------
-- Safety routing
-- A formation journal must never absorb a mandated report. When a practice
-- surfaces something that belongs in the real channel, the system records THAT
-- the person was routed — never what they disclosed — and the actual report
-- happens in the organization's actual incident system.
-- -----------------------------------------------------------------------------

CREATE TYPE safety_route AS ENUM (
  'mandated_report', 'incident_report', 'clinical_escalation', 'employee_assistance'
);

CREATE TABLE safety_referral (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  person_id     uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  session_id    uuid REFERENCES practice_session(id) ON DELETE SET NULL,
  route         safety_route NOT NULL,
  surfaced_at   timestamptz NOT NULL DEFAULT now(),
  acknowledged  boolean NOT NULL DEFAULT false
  -- Intentionally NO detail column. What was disclosed belongs in the
  -- organization's incident system, under its retention and legal obligations —
  -- not here, where it would become discoverable formation data.
);

-- -----------------------------------------------------------------------------
-- Rafiki — separately stored and separately deletable
-- Constitution §3: a person can delete their Rafiki history without destroying
-- their own journal, and can use everything else without Rafiki at all.
-- -----------------------------------------------------------------------------

CREATE TABLE rafiki_turn (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenant(id) ON DELETE CASCADE,
  person_id   uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  asked_at    timestamptz NOT NULL DEFAULT now(),
  prompt      text NOT NULL,
  reply       text NOT NULL,
  prompt_ref  text NOT NULL   -- git ref of the system prompt that produced it
);

CREATE TABLE consent_record (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id   uuid NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  document    text NOT NULL,
  version     text NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  withdrawn_at timestamptz
);

-- =============================================================================
-- VIEWS — the only sanctioned path to organizational insight
-- =============================================================================

-- Participation, with no route to content. Safe for supervisors and directors.
CREATE VIEW v_participation AS
SELECT
  ps.tenant_id, ps.person_id, ps.cohort_id, ps.kind,
  date_trunc('week', ps.occurred_at) AS week,
  count(*) AS sessions
FROM practice_session ps
GROUP BY 1,2,3,4,5;

-- Follow-through: the Trust Equation, made observable.
-- Integrity is Say → Do (kept). Accountability is Did → Said (reported when
-- missed). A miss that was reported is accountability working, not a failure —
-- which is why 'missed_and_reported' counts toward trust and 'missed_silently'
-- is the only state that does not. §5: this describes practice, not persons.
CREATE VIEW v_follow_through AS
SELECT
  c.tenant_id,
  c.person_id,
  count(*) FILTER (WHERE c.state = 'kept')                AS kept,
  count(*) FILTER (WHERE c.state = 'renegotiated')        AS renegotiated,
  count(*) FILTER (WHERE c.state = 'missed_and_reported') AS missed_and_reported,
  count(*) FILTER (WHERE c.state = 'missed_silently')     AS missed_silently,
  count(*) FILTER (WHERE c.state <> 'open')               AS resolved,
  round(
    100.0 * count(*) FILTER (WHERE c.state IN ('kept','renegotiated','missed_and_reported'))
    / NULLIF(count(*) FILTER (WHERE c.state <> 'open'), 0)
  ) AS alignment_pct
FROM commitment c
GROUP BY 1,2;

-- Organizational pressure patterns, k-anonymous by construction.
-- Constitution §2: an aggregate too small to protect a person is WITHHELD, not
-- shown with a caveat. The HAVING clause is that rule, in the only place it
-- cannot be forgotten.
CREATE VIEW v_pressure_patterns AS
SELECT
  ps.tenant_id,
  ps.cohort_id,
  sc.context,
  sc.diagnosis,
  count(*)                        AS occurrences,
  count(DISTINCT ps.person_id)    AS distinct_people
FROM practice_session ps
JOIN soil_check sc ON sc.session_id = ps.session_id
JOIN tenant t      ON t.id = ps.tenant_id
GROUP BY 1,2,3,4
HAVING count(DISTINCT ps.person_id) >= (SELECT min_aggregate_n FROM tenant WHERE id = ps.tenant_id);

-- Role-level view of where unnecessary urgency concentrates. Same floor.
CREATE VIEW v_urgency_by_role AS
SELECT
  ps.tenant_id,
  p.primary_role,
  count(*) FILTER (WHERE sc.diagnosis = 'unnecessary')       AS unnecessary,
  count(*)                                                   AS total_checks,
  count(DISTINCT ps.person_id)                               AS distinct_people,
  round(100.0 * count(*) FILTER (WHERE sc.diagnosis = 'unnecessary') / count(*)) AS unnecessary_pct
FROM practice_session ps
JOIN soil_check sc ON sc.session_id = ps.session_id
JOIN person p      ON p.id = ps.person_id
GROUP BY 1,2
HAVING count(DISTINCT ps.person_id) >= (SELECT min_aggregate_n FROM tenant WHERE id = ps.tenant_id);
