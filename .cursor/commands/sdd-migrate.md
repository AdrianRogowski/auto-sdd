# /sdd-migrate - Migrate from SDD 1.0 to 2.0

Upgrade an existing SDD 1.0 project to SDD 2.0 with compound learning and automation.

## Detection

Check for SDD version:

```
1. If .specs/.sdd-version exists → read version
2. If no version file but .specs/ exists → SDD 1.0
3. If no .specs/ → not an SDD project
```

## Migration Steps (1.0 → 2.0)

### Step 1: Create Learnings Folder

```bash
mkdir -p .specs/learnings
```

Create these files:
- `.specs/learnings/index.md`
- `.specs/learnings/testing.md`
- `.specs/learnings/performance.md`
- `.specs/learnings/security.md`
- `.specs/learnings/api.md`
- `.specs/learnings/design.md`
- `.specs/learnings/general.md`

Use the templates from the SDD 2.0 repo.

### Step 2: Add YAML Frontmatter to Existing Specs

For each `.specs/features/**/*.feature.md`:

1. Read the file
2. Extract feature name from `# Feature Name` header
3. Extract domain from file path
4. Add YAML frontmatter:

```yaml
---
feature: {extracted name}
domain: {from path}
source: {find Source File line or leave empty}
tests: []
components: []
design_refs: []
status: implemented
created: {file creation date or today}
updated: {today}
---
```

### Step 3: Update Commands

Replace all files in `.cursor/commands/` and `.claude/commands/` with SDD 2.0 versions.

New command added:
- `compound.md`

### Step 4: Update Rules

Replace all files in `.cursor/rules/` with SDD 2.0 versions.

New rule added:
- `compound.mdc`

### Step 5: Add Hooks

Create:
- `.cursor/hooks.json`
- `.cursor/hooks/regenerate-mapping.sh`
- `.cursor/hooks/check-conflicts.sh`
- `.cursor/hooks/session-end.sh`

Make hook scripts executable:
```bash
chmod +x .cursor/hooks/*.sh
```

### Step 6: Add Automation Scripts

Create `scripts/` directory with:
- `generate-mapping.sh`
- `nightly-review.sh`
- `overnight-autonomous.sh`
- `setup-overnight.sh`
- `uninstall-overnight.sh`
- `launchd/` (plist files)

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### Step 7: Create Supporting Files

- `.env.local.example`
- `logs/.gitkeep`

### Step 8: Regenerate mapping.md

Run:
```bash
./scripts/generate-mapping.sh
```

This replaces the old complex mapping.md with the new auto-generated format.

### Step 9: Update CLAUDE.md

Replace with SDD 2.0 version (includes learnings section, compound command).

### Step 10: Create Version File

```bash
echo "2.0" > .specs/.sdd-version
```

---

## Output

```
═══════════════════════════════════════════════════════════════════
                    SDD MIGRATION: 1.0 → 2.0
═══════════════════════════════════════════════════════════════════

Detected: SDD 1.0 (no version file, .specs/ exists)

Migration Plan:
├── Create .specs/learnings/ folder (7 files)
├── Add YAML frontmatter to {N} feature specs
├── Update commands (add /compound)
├── Update rules (add compound.mdc)
├── Add hooks system
├── Add automation scripts
├── Regenerate mapping.md
├── Update CLAUDE.md
└── Create version file

Proceed? [y/n]
```

After confirmation:

```
═══════════════════════════════════════════════════════════════════
                    MIGRATION COMPLETE
═══════════════════════════════════════════════════════════════════

✓ Created .specs/learnings/ (7 files)
✓ Added frontmatter to 12 feature specs
✓ Updated 16 commands
✓ Updated 3 rules
✓ Added hooks system
✓ Added automation scripts
✓ Regenerated mapping.md
✓ Updated CLAUDE.md
✓ Version: 2.0

New capabilities:
• /compound - Extract learnings from sessions
• Overnight automation (run ./scripts/setup-overnight.sh)
• Auto-generated mapping (no more merge conflicts)
• Category-based learnings

Next steps:
1. Review .specs/learnings/ structure
2. Run /compound at end of your next session
3. (Optional) Set up overnight automation
```

---

## Already on 2.0

If `.specs/.sdd-version` = 2.0:

```
SDD version: 2.0 (current)
No migration needed.

To check for updates, run:
  git auto --check-update
```

---

## Not an SDD Project

If no `.specs/` directory:

```
This doesn't appear to be an SDD project.

To install SDD 2.0, run:
  git auto

Or for SDD 1.0:
  git sdd
```
