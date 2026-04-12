---
description: Create or update project-wide invariants that every feature must satisfy (.specs/constitution.md)
---

Create or update the project constitution: $ARGUMENTS

## What This Command Does

The constitution defines **non-negotiable constraints that apply to every feature**. Unlike specs (per-feature behavior) or learnings (discovered patterns), constitutional rules are enforced upfront — `/spec-first` reads the constitution and every generated spec must declare compliance.

Think of it as the difference between:
- **A spec**: "When the user clicks Submit, save the form and show a toast"
- **A constitutional rule**: "No feature, ever, stores passwords in plaintext"

```
/constitution → .specs/constitution.md
    ↓
/spec-first reads it → every spec includes Constitutional Compliance section
    ↓
/tdd implements with constraints in context
    ↓
/catch-drift can verify compliance hasn't eroded
```

---

## Mode Detection

| Condition | Mode |
|-----------|------|
| No constitution.md or only template | **Create** — generate from project context |
| constitution.md has real content | **Update** — add/revise rules |
| `--audit` flag | **Audit** — check all specs for compliance sections |

---

## Create Mode

### Step 1: Read Context

Read these files to understand the project:
- `.specs/strategy.md` — business strategy (enterprise = heavier security; PLG = different constraints)
- `.specs/vision.md` — tech stack, design principles, app purpose
- `.specs/personas/*.md` — who uses this (technical level affects what constraints matter)
- `.specs/learnings/security.md` — any existing security patterns
- Scan codebase for tech stack indicators (`package.json`, `prisma/schema.prisma`, auth config, etc.)

### Step 2: Determine Constraint Profile

Based on context, determine which constraint categories apply:

| Signal | Constraint Weight |
|--------|------------------|
| Strategy says enterprise / B2B | Heavy auth, data handling, audit |
| Strategy says PLG / consumer | Lighter auth, heavier UX constraints |
| Tech stack has auth (NextAuth, Clerk, etc.) | Auth constraints apply |
| Tech stack has database (Prisma, Drizzle, etc.) | Data handling constraints apply |
| Vision mentions API / integrations | API security constraints apply |
| Strategy mentions handling PII / financial data | Privacy and compliance constraints |
| Internal tool only | Lighter overall, focus on error handling |

### Step 3: Generate Constitution

Write `.specs/constitution.md` with rules tailored to the project. Don't dump a generic checklist — generate rules that actually apply to THIS project's tech stack and context.

**Every rule must be:**
- **Verifiable** — an agent can check compliance (not vague aspirations)
- **Actionable** — tells you what to do, not just what to avoid
- **Grounded** — connected to the project's actual tech stack and context

### Step 4: Show for Approval

Present the constitution and explain the reasoning. The user should understand why each category exists and be able to add/remove rules.

---

## Constitution Format

```markdown
# Project Constitution

_Non-negotiable constraints that apply to ALL features._
_Version: 1.0 | Last updated: YYYY-MM-DD_

---

## How This Is Used

- `/spec-first` reads this file and adds a **Constitutional Compliance** section to every spec
- Each spec must mark which rules apply, which are N/A, and flag any conflicts
- `/constitution --audit` scans all specs for compliance coverage

---

## Authentication & Authorization

- [ ] All authenticated routes verify session server-side (no client-trust)
- [ ] Password/token fields never logged, never stored in plaintext
- [ ] Session tokens use httpOnly + Secure + SameSite=Strict cookies
- [ ] Role/permission checks happen at the API layer, not just UI

## Data Handling

- [ ] No PII written to application logs
- [ ] User data deletion cascades to all related records
- [ ] File uploads validated for type and size before processing

## API Security

- [ ] All external API calls use env vars for credentials (no hardcoded keys)
- [ ] Rate limiting applied to all public-facing endpoints
- [ ] Error responses never expose stack traces or internal paths

## Error Handling

- [ ] All async operations have explicit error boundaries
- [ ] Failed states have defined user-visible fallback behavior in spec
- [ ] External service failures degrade gracefully (no blank pages)

## Dependencies

- [ ] No new dependencies added without explicit mention in spec
- [ ] Security-critical packages pinned to exact versions (no ^)

## [Project-Specific Category]

_Add categories based on the project's domain — HIPAA, PCI, GDPR, accessibility, etc._
```

**Important:** The categories and specific rules should be generated based on the project context, not copied from a generic template. A CLI tool doesn't need cookie rules. An internal dashboard doesn't need rate limiting. An app handling medical data needs HIPAA constraints.

---

## Update Mode

When constitution.md already exists:

1. Read current constitution.md
2. Read strategy.md, vision.md, learnings/security.md for changes
3. Read recent feature specs for patterns that suggest new rules
4. Present: what's current, what should be added, what's obsolete
5. Apply approved changes with version bump

---

## Audit Mode (`--audit`)

Scan all feature specs for constitutional compliance:

1. Read `.specs/constitution.md` for the rule list
2. Read all `.specs/features/**/*.feature.md`
3. For each spec, check:
   - Does it have a `## Constitutional Compliance` section?
   - Are all applicable rules addressed?
   - Are there any `[CONSTITUTIONAL CONFLICT]` flags?
4. Output report:

```
Constitutional Audit Report
============================
Specs audited: 12
Fully compliant: 8
Missing compliance section: 2
  ⚠️  payments/checkout.feature.md
  ⚠️  api/webhooks.feature.md
Conflicts flagged: 1
  ⚠️  api/export.feature.md — CONFLICT: rate limiting not implemented (needs external gateway)
Not applicable (stubs): 1
  ℹ️  settings/theme.feature.md (status: stub, not yet specced)
```

---

## After Saving

```
✅ Constitution saved to .specs/constitution.md

Rules by category:
- Authentication: 4 rules
- Data Handling: 3 rules
- API Security: 3 rules
- Error Handling: 3 rules
- Dependencies: 2 rules

This will be read by /spec-first when generating feature specs.
Every spec will include a Constitutional Compliance section.

Run /constitution --audit to check existing specs for compliance.
```

---

## How /spec-first Uses the Constitution

When `/spec-first` loads context (Step 1), it reads `constitution.md` and adds this section to every generated spec:

```markdown
## Constitutional Compliance

| Rule | Applies | Status |
|------|---------|--------|
| Auth: Server-side session verification | ✅ Yes | Addressed in Scenario: Auth redirect |
| Auth: No plaintext passwords | ✅ Yes | Uses bcrypt (existing auth module) |
| Data: No PII in logs | ✅ Yes | Email redacted in error logs |
| API: Rate limiting on public endpoints | N/A | Internal endpoint only |
| Error: Graceful degradation | ✅ Yes | Addressed in Scenario: API failure |
| Deps: No new deps without mention | ✅ Yes | No new dependencies |
```

If a constitutional rule cannot be satisfied:
```markdown
| API: Rate limiting on public endpoints | ⚠️ CONFLICT | Public endpoint, but rate limiting requires infrastructure not yet available. Tracked in Open Questions. |
```

---

## Command Triggers

| User says | Action |
|-----------|--------|
| "constitution" | Run `/constitution` |
| "project constraints" | Run `/constitution` |
| "security rules" | Run `/constitution` |
| "invariants" | Run `/constitution` |
| "non-negotiables" | Run `/constitution` |
| "audit specs" | Run `/constitution --audit` |
