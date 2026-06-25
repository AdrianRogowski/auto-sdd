---
description: Discover (brownfield) or define (greenfield) the database migration strategy and write .specs/migrations.md
---

Create or update the migration playbook: $ARGUMENTS

# Infer Migrations — Discover or Define the Database Migration Strategy

Create `.specs/migrations.md` — the project's migration playbook. On a **brownfield** project this command *infers* the conventions already in use (tool, naming, ordering, reversibility, backfill habits). On a **greenfield** project it *defines* a sensible strategy from the tech stack and constitution.

This is the schema analog of `/spec-init`: it captures conventions once so every feature's `## Migration Plan` and the `/tdd` migration verify step follow the same rules.

```
/infer-migrations
      │
      ▼
┌──────────────────────────────────────────────────────────────────┐
│  DETECT tool → READ migrations dir → INFER conventions            │
└──────────────────────────────────────────────────────────────────┘
      │
      ▼
.specs/migrations.md (full playbook)  +  .cursor/rules/migrations.mdc (thin, always-applied)
      │
      ▼
/spec-first reads it → every schema-touching spec gets a Migration Plan
/tdd verifies it     → up → down → up on a scratch DB (non-blocking)
/constitution        → "Schema & Migrations" rules enforce it
```

## When to Use

- First time adopting SDD on a project that already has migrations (infer reality)
- Greenfield project that will use a database (define the strategy upfront)
- After switching ORM/migration tool (re-infer)
- When `/spec-first` or `/tdd` reports there is no `.specs/migrations.md`

---

## Mode Detection

| Condition | Mode |
|-----------|------|
| A migrations directory exists with real migrations | **Infer** — read them, derive conventions |
| ORM/schema config exists but no migrations yet | **Bootstrap** — define conventions from the tool's defaults + constitution |
| No database tooling detected | **Skip** — report that the project has no DB layer; do not create the file |
| `.specs/migrations.md` already has real content | **Update** — re-infer, show diff, preserve manual edits |

---

## Step 1: Detect the Migration Tool

Scan for tool indicators. Do **not** load or scrape any external sources — read only local files.

| Tool | Indicators | Migrations live in |
|------|-----------|--------------------|
| Prisma | `prisma/schema.prisma`, `prisma/migrations/` | `prisma/migrations/` |
| Drizzle | `drizzle.config.*`, `drizzle/` | `drizzle/` or configured `out` |
| Knex | `knexfile.*`, `migrations/` | `migrations/` |
| TypeORM | `ormconfig.*`, `data-source.ts`, `migration/` | `src/migration/` |
| Alembic (SQLAlchemy) | `alembic.ini`, `alembic/versions/` | `alembic/versions/` |
| Django | `manage.py`, `**/migrations/` | each app's `migrations/` |
| Rails / ActiveRecord | `db/migrate/`, `config/database.yml` | `db/migrate/` |
| Flyway | `flyway.conf`, `db/migration/` | versioned SQL files |
| Sqitch | `sqitch.plan`, `deploy/` `revert/` `verify/` | `deploy/` + `revert/` |
| golang-migrate | `migrations/*.up.sql` + `*.down.sql` | `migrations/` |
| Raw SQL / custom | loose `.sql` files, a `db/` folder, a custom runner script | wherever they are |

Report the detected tool and the migration directory. If multiple tools appear (e.g. monorepo), document each.

## Step 2: Read the Migrations

Read the migration files (newest several in full, skim the rest) and the schema definition. From them, **infer** — do not assume — the following:

- **Naming convention**: timestamp prefix (`20240115_…`), sequential integer (`0007_…`), semantic (`add_user_email`), or hash. Quote a real example.
- **Ordering**: how the tool determines apply order (timestamp, sequence number, `sqitch.plan`, dependency graph).
- **Reversibility**: do migrations ship a `down`/revert? Look for `down()`, `.down.sql`, `revert/`, Alembic `downgrade()`. Classify: always reversible / sometimes / never.
- **Backfill habits**: are data backfills done *inside* the schema migration, in *separate* data migrations, or in app code? Find an example.
- **Transactionality**: are migrations wrapped in transactions? Any `BEGIN`/`COMMIT`, `--no-transaction` flags, or tool defaults.
- **Destructive-change handling**: search history for `DROP COLUMN`, `DROP TABLE`, type narrowing, `NOT NULL` added to existing columns. Did they do it directly or via expand-contract (add new → backfill → switch reads → drop old)?
- **Zero-downtime signals**: concurrent index creation (`CREATE INDEX CONCURRENTLY`), nullable-then-backfill patterns, feature flags around schema reads.
- **Apply command**: the actual command used (`prisma migrate deploy`, `npx drizzle-kit push`, `alembic upgrade head`, `rails db:migrate`, etc.) — this should match `MIGRATION_CMD` in `.env.local`.
- **Environments**: any dev/staging/prod distinction in how migrations run (e.g. `migrate dev` vs `migrate deploy`).

If a convention is inconsistent across history, record it as **inconsistent** and note the most recent practice as the going-forward default.

## Step 3 (Bootstrap mode only): Define a Strategy

If there are no migrations yet, define a default strategy from the tool's idioms plus `.specs/constitution.md`:
- Default to **reversible** migrations where the tool supports them.
- Backfills go in **separate** data migrations, never blocking a schema change.
- Destructive changes require **expand-contract** phasing.
- Pick the standard apply command for the detected tool.

Mark these as "defined (no history yet)" so a later `/infer-migrations` run knows to re-check against real migrations.

## Step 4: Write `.specs/migrations.md`

Use this format:

```markdown
# Migration Playbook

_How this project changes its database schema. Read by /spec-first, /tdd, and /constitution._
_Tool: {detected} | Mode: {inferred from history | defined (no history)} | Updated: YYYY-MM-DD_

## Tool & Layout
- **Tool**: {Prisma | Drizzle | Alembic | …}
- **Migrations dir**: `{path}`
- **Schema source of truth**: `{path}`
- **Apply command**: `{command}`  ← keep in sync with MIGRATION_CMD in .env.local

## Conventions (going-forward defaults)
- **Naming**: {convention} — e.g. `{real example}`
- **Ordering**: {how order is determined}
- **Reversibility**: {always | when feasible | never} — {how down/revert is written}
- **Transactions**: {wrapped | per-statement | tool default}
- **Backfills**: {separate data migration | in-migration | app code} — {why}

## Change Classification
| Class | Examples | Required handling |
|-------|----------|-------------------|
| Additive (safe) | new nullable column, new table, new index | direct; add index concurrently if large table |
| Destructive | drop column/table, type narrowing, add NOT NULL to existing | expand-contract; never single-step |
| Data transform | backfill, re-key, denormalize | separate reversible data migration; chunked if large |

## Expand-Contract Rule
For any change that breaks currently-running code:
1. **Expand** — add the new shape (nullable/parallel), deploy.
2. **Backfill** — migrate data in a separate step.
3. **Migrate reads/writes** — switch app code to the new shape.
4. **Contract** — drop the old shape in a later migration.

## Reversibility Checklist (used by /tdd verify)
- [ ] Migration applies cleanly forward (up)
- [ ] Migration reverses cleanly (down/revert) OR is explicitly marked irreversible with reason
- [ ] Re-applying forward after a down is idempotent
- [ ] Backfill is reversible or safely re-runnable

## Known Exceptions / Tech Debt
- {migrations that broke the rules, and why}
```

## Step 5: Write the Always-Applied Rule

Create or update `.cursor/rules/migrations.mdc` (`alwaysApply: true`) as a **thin** summary that points to `.specs/migrations.md`. This guarantees the core rules are in every agent's context window without loading the full playbook. Mirror the structure of `.cursor/rules/design-tokens.mdc`. Keep it under ~40 lines: tool, apply command, naming, reversibility rule, expand-contract one-liner, and a pointer to the full file.

## Step 6: Reconcile `.env.local`

Compare the detected apply command to `MIGRATION_CMD` in `.env.local`:
- If `MIGRATION_CMD` is empty, tell the user to set it (or that `build-loop-local.sh` will auto-detect it).
- If it disagrees with what you inferred, flag the mismatch.

---

## After Running

```
✅ Migration playbook written to .specs/migrations.md
✅ Always-applied rule written to .cursor/rules/migrations.mdc

Tool: Prisma (prisma/migrations/)
Apply command: npx prisma migrate deploy
Naming: timestamp_description — e.g. 20240115093000_add_deal_stage
Reversibility: when feasible (down migrations present in 12/18)
Backfills: separate data migrations

This will be read by:
- /spec-first → adds a Migration Plan to any spec that changes the Data Model
- /tdd        → verifies up → down → up on a scratch DB (non-blocking)
- /constitution → enforce via the Schema & Migrations category

Next: run /constitution to add schema-change rules, or /spec-first to build a feature.
```

---

## Relationship to Other Commands

| Command | How it uses the playbook |
|---------|--------------------------|
| `/spec-first` | Reads `.specs/migrations.md`; when a feature changes the Data Model, emits a `## Migration Plan` following these conventions |
| `/tdd` | Runs the Reversibility Checklist as a non-blocking verify step after GREEN |
| `/constitution` | "Schema & Migrations" rules reference these conventions for the per-spec compliance table |
| `build-loop-local.sh` | Applies migrations via `MIGRATION_CMD` (operational layer — this command defines the design layer) |

---

## Command Triggers

| User says | Action |
|-----------|--------|
| "infer migrations" | Run `/infer-migrations` |
| "migration strategy" | Run `/infer-migrations` |
| "migration playbook" | Run `/infer-migrations` |
| "how do we do migrations" | Run `/infer-migrations` |
| "document our migrations" | Run `/infer-migrations` |
| "schema change strategy" | Run `/infer-migrations` |
