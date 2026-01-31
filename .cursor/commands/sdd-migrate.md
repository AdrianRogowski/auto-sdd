# /sdd-migrate - Migrate from SDD 1.0 to 2.0

Upgrade an existing SDD 1.0 project to SDD 2.0 with compound learning and automation.

**Prerequisites**: Run `git auto-upgrade` first to stage the 2.0 files in `.sdd-upgrade/`.

## Step 0: Check Prerequisites

First, verify the staging directory exists:

```
Check for .sdd-upgrade/ directory
├── If exists → Continue with migration
└── If missing → ERROR: "Run 'git auto-upgrade' first to stage the 2.0 files"
```

Also check this is an SDD project:
```
Check for .specs/ directory
├── If exists → SDD project, continue
└── If missing → ERROR: "Not an SDD project. Use 'git auto' for fresh install"
```

Check version:
```
Check .specs/.sdd-version
├── If "2.0" → Already migrated, nothing to do
├── If missing → SDD 1.0, proceed with migration
└── If other → Future version, warn user
```

---

## Step 1: Inventory Existing Commands

List all files in `.cursor/commands/` and categorize them:

**Stock SDD 1.0 commands** (will be replaced from staging):
- catch-drift.md
- check-coverage.md
- code-review.md
- design-component.md
- design-tokens.md
- document-code.md
- fix-bug.md
- formalize.md
- prototype.md
- refactor.md
- spec-first.md
- spec-init.md
- start-feature.md
- update-test-docs.md
- verify-test-counts.md

**Any other .md files** in commands/ are custom → preserve them.

Output:
```
Command Inventory:
├── Stock commands to update: [count]
│   • spec-first.md
│   • spec-init.md
│   • ... (list all found)
├── Custom commands to preserve: [count]
│   • my-custom-command.md (if any)
└── New commands to add: 2
    • compound.md
    • sdd-migrate.md
```

---

## Step 2: Inventory Existing Rules

List all files in `.cursor/rules/`:

**Stock SDD 1.0 rules** (will be replaced):
- design-tokens.mdc
- specs-workflow.mdc

**Any other .mdc files** are custom → preserve them.

---

## Step 3: Create Learnings Folder

Copy from staging:
```bash
cp -r .sdd-upgrade/.specs/learnings .specs/learnings
```

This creates:
- `.specs/learnings/index.md`
- `.specs/learnings/testing.md`
- `.specs/learnings/performance.md`
- `.specs/learnings/security.md`
- `.specs/learnings/api.md`
- `.specs/learnings/design.md`
- `.specs/learnings/general.md`

---

## Step 4: Add YAML Frontmatter to Existing Specs

For each `.specs/features/**/*.feature.md`:

1. Read the file
2. Check if it already starts with `---` (has frontmatter) → skip
3. Extract feature name from first `# ` heading
4. Extract domain from file path (e.g., `auth` from `.specs/features/auth/login.feature.md`)
5. Look for `**Source File**:` to extract source path
6. Prepend frontmatter:

```yaml
---
feature: {extracted name}
domain: {from path}
source: {from Source File line or empty}
tests: []
components: []
design_refs: []
status: implemented
created: {today's date}
updated: {today's date}
---
```

**Important**: Do NOT modify any other content in the spec. Just prepend frontmatter.

---

## Step 5: Update Stock Commands

For each stock command found in Step 1:
```bash
cp .sdd-upgrade/.cursor/commands/{name}.md .cursor/commands/{name}.md
```

Do the same for `.claude/commands/` if it exists.

**Do NOT touch custom commands** - they stay exactly as they are.

---

## Step 6: Update Stock Rules

For each stock rule found in Step 2:
```bash
cp .sdd-upgrade/.cursor/rules/{name}.mdc .cursor/rules/{name}.mdc
```

Add the new compound rule:
```bash
cp .sdd-upgrade/.cursor/rules/compound.mdc .cursor/rules/compound.mdc
```

---

## Step 7: Add Hooks

If `.cursor/hooks.json` doesn't exist:
```bash
cp .sdd-upgrade/.cursor/hooks.json .cursor/hooks.json
cp -r .sdd-upgrade/.cursor/hooks .cursor/hooks
chmod +x .cursor/hooks/*.sh
```

If hooks already exist, warn user and skip.

---

## Step 8: Add Automation Scripts

```bash
cp -r .sdd-upgrade/scripts .
chmod +x scripts/*.sh
```

Also copy supporting files:
```bash
cp .sdd-upgrade/.env.local.example . 2>/dev/null || true
mkdir -p logs
```

---

## Step 9: Backup and Regenerate mapping.md

```bash
cp .specs/mapping.md .specs/mapping.md.backup
./scripts/generate-mapping.sh
```

Tell user: "Old mapping backed up to .specs/mapping.md.backup"

---

## Step 10: Update CLAUDE.md

```bash
cp .sdd-upgrade/CLAUDE.md CLAUDE.md
```

---

## Step 11: Create Version File

```bash
echo "2.0" > .specs/.sdd-version
```

---

## Step 12: Cleanup Staging Directory

```bash
rm -rf .sdd-upgrade
```

---

## Step 13: Summary

Output final summary:

```
═══════════════════════════════════════════════════════════════════
                    MIGRATION COMPLETE: 1.0 → 2.0
═══════════════════════════════════════════════════════════════════

✓ Created .specs/learnings/ (7 files)
✓ Added frontmatter to [N] feature specs
✓ Updated [N] stock commands
✓ Preserved [N] custom commands
✓ Added compound.md, sdd-migrate.md
✓ Updated [N] stock rules, added compound.mdc
✓ Added hooks system
✓ Added automation scripts
✓ Backed up mapping.md → mapping.md.backup
✓ Regenerated mapping.md
✓ Updated CLAUDE.md
✓ Cleaned up staging directory
✓ Version: 2.0

Custom commands preserved (untouched):
  • [list any custom commands]

Custom rules preserved (untouched):
  • [list any custom rules]

New capabilities:
  • /compound - Extract learnings from sessions
  • Overnight automation (run ./scripts/setup-overnight.sh)
  • Auto-generated mapping (no more merge conflicts)
  • Category-based learnings in .specs/learnings/

Note: Existing feature specs were NOT modified beyond adding
frontmatter. They don't need ASCII mockups to work.
```

---

## Error Handling

| Error | Message |
|-------|---------|
| No `.sdd-upgrade/` | "Run 'git auto-upgrade' first to stage the 2.0 files" |
| No `.specs/` | "Not an SDD project. Use 'git auto' for fresh install" |
| Already 2.0 | "Already on SDD 2.0. No migration needed." |
| Script fails | Show error, don't delete staging dir so user can retry |

---

## Rollback

If something goes wrong:

```bash
# Restore mapping
mv .specs/mapping.md.backup .specs/mapping.md

# Remove version to re-run migration
rm .specs/.sdd-version

# Re-run git auto-upgrade to get fresh staging
git auto-upgrade
```
