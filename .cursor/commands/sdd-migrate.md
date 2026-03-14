# /sdd-migrate - Upgrade SDD to latest version

Upgrade an existing SDD project to the latest version from the staged template files.

If `.sdd-upgrade/` doesn't exist yet, this command automatically runs `git auto-upgrade` to stage the files first.

## Step 0: Check Prerequisites

```
Check for .specs/ directory
├── If exists → SDD project, continue
└── If missing → ERROR: "Not an SDD project. Use 'git auto' for fresh install"

Check for .sdd-upgrade/ directory
├── If exists → Continue to version check
└── If missing → Auto-stage by running: git auto-upgrade
    ├── If succeeds → Continue to version check
    └── If fails → ERROR: "Failed to stage upgrade files. Check your network connection and try 'git auto-upgrade' manually."
```

### Version Check

```
Read CURRENT version from: VERSION or .specs/.sdd-version (or "1.0.0" if neither exists)
Read TARGET version from: .sdd-upgrade/VERSION (or "2.0.0" if missing)

Compare versions:
├── TARGET > CURRENT → Proceed with upgrade (label: UPGRADE)
├── TARGET = CURRENT → Proceed with re-sync (label: RE-SYNC)
└── TARGET < CURRENT → "Installed version is newer than template. Skipping."
```

**Re-sync rationale:** Even at the same version, files may have drifted (partial previous migration, manual edits, or template patches without a version bump). A re-sync ensures all stock files match the template.

---

## Step 1: Inventory Commands and Rules

**Do NOT use a hardcoded list of stock commands.** Instead, determine stock vs custom dynamically:

1. List all `.md` files in `.sdd-upgrade/.cursor/commands/` → these are the **stock commands** (the template's commands)
2. List all `.md` files in the project's `.cursor/commands/` → these are the **installed commands**
3. **Stock (to sync)**: any file that exists in `.sdd-upgrade/.cursor/commands/`
4. **Custom (to preserve)**: any file in the project's `.cursor/commands/` that does NOT exist in `.sdd-upgrade/.cursor/commands/`

Do the same for:
- `.cursor/rules/*.mdc` vs `.sdd-upgrade/.cursor/rules/*.mdc`
- `.claude/commands/*.md` vs `.sdd-upgrade/.claude/commands/*.md` (if `.claude/` exists in staging)

Output inventory:

```
Command Inventory:
├── Stock commands to update: [count]
│   • spec-first.md, tdd.md, refactor.md, ... (all from staging)
├── New commands to add: [count]
│   • [commands in staging but not installed]
├── Custom commands to preserve: [count]
│   • [commands installed but not in staging]
└── Rules to update: [count]
    • specs-workflow.mdc, design-tokens.mdc, ...
```

---

## Step 2: Create Missing Directories

Ensure these exist (create if missing, skip if present):

```bash
mkdir -p .specs/learnings
mkdir -p .specs/design-system/components
mkdir -p .specs/personas
mkdir -p logs
```

---

## Step 3: Sync Learnings Templates

If `.specs/learnings/index.md` doesn't exist, copy learnings templates from staging:

```bash
cp -n .sdd-upgrade/.specs/learnings/*.md .specs/learnings/
```

Use `-n` (no-clobber) to avoid overwriting existing learnings files that may have content.

---

## Step 4: Add YAML Frontmatter to Existing Specs

For each `.specs/features/**/*.feature.md`:

1. Check if it already starts with `---` (has frontmatter) → skip
2. Extract feature name from first `# ` heading
3. Extract domain from file path
4. Look for `**Source File**:` to extract source path
5. Prepend frontmatter:

```yaml
---
feature: { extracted name }
domain: { from path }
source: { from Source File line or empty }
tests: []
components: []
design_refs: []
status: implemented
created: { today's date }
updated: { today's date }
---
```

**Important**: Do NOT modify any other content. Just prepend frontmatter to specs that lack it.

---

## Step 5: Sync Stock Commands

For each `.md` file in `.sdd-upgrade/.cursor/commands/`:

```bash
cp .sdd-upgrade/.cursor/commands/{name}.md .cursor/commands/{name}.md
```

This replaces existing stock commands AND adds new ones.

Do the same for `.claude/commands/` if the staging directory has them:

```bash
[ -d .sdd-upgrade/.claude/commands ] && cp .sdd-upgrade/.claude/commands/*.md .claude/commands/
```

**Do NOT touch files that only exist in the project's commands/ (custom commands).**

---

## Step 6: Sync Stock Rules

For each `.mdc` file in `.sdd-upgrade/.cursor/rules/`:

```bash
cp .sdd-upgrade/.cursor/rules/{name}.mdc .cursor/rules/{name}.mdc
```

**Do NOT touch custom rules.**

---

## Step 7: Sync Hooks

If `.sdd-upgrade/.cursor/hooks.json` exists:

```bash
cp .sdd-upgrade/.cursor/hooks.json .cursor/hooks.json
cp -r .sdd-upgrade/.cursor/hooks .cursor/hooks
chmod +x .cursor/hooks/*.sh 2>/dev/null || true
```

---

## Step 8: Sync Automation Scripts

```bash
cp -r .sdd-upgrade/scripts .
chmod +x scripts/*.sh
```

Also copy supporting files:

```bash
cp .sdd-upgrade/.env.local.example . 2>/dev/null || true
```

---

## Step 9: Sync CLAUDE.md and .gitignore

```bash
cp .sdd-upgrade/CLAUDE.md CLAUDE.md
cp .sdd-upgrade/.gitignore .gitignore 2>/dev/null || true
```

---

## Step 10: Regenerate Mapping

```bash
cp .specs/mapping.md .specs/mapping.md.backup 2>/dev/null || true
./scripts/generate-mapping.sh
```

---

## Step 11: Update Version

```bash
cp .sdd-upgrade/VERSION . 2>/dev/null || echo "2.1.0" > VERSION
cp VERSION .specs/.sdd-version
```

---

## Step 12: Cleanup Staging Directory

```bash
rm -rf .sdd-upgrade
```

---

## Step 13: Summary

Output final summary. Use the label from the version check (UPGRADE or RE-SYNC):

```
═══════════════════════════════════════════════════════════════════
          {UPGRADE|RE-SYNC} COMPLETE: {old} → {new}
═══════════════════════════════════════════════════════════════════

✓ Synced [N] stock commands (replaced/added)
✓ Preserved [N] custom commands (untouched)
✓ Synced [N] stock rules
✓ Synced automation scripts
✓ Synced hooks
✓ Updated CLAUDE.md
✓ Backed up mapping.md → mapping.md.backup
✓ Regenerated mapping.md
✓ Cleaned up staging directory
✓ Version: {new version}

Custom commands preserved (untouched):
  • [list any custom commands]

Custom rules preserved (untouched):
  • [list any custom rules]

What's new in this version:
  [Read .sdd-upgrade/CHANGELOG.md if it exists, otherwise skip this section]
```

---

## Error Handling

| Error | Message |
|-------|---------|
| No `.sdd-upgrade/` | "Run 'git auto-upgrade' first to stage the latest files" |
| No `.specs/` | "Not an SDD project. Use 'git auto' for fresh install" |
| Same version | Re-sync all stock files (files may have drifted) |
| Script fails | Show error, don't delete staging dir so user can retry |

---

## Rollback

If something goes wrong:

```bash
# Restore mapping
mv .specs/mapping.md.backup .specs/mapping.md

# Re-run git auto-upgrade to get fresh staging
git auto-upgrade

# Re-run migration
/sdd-migrate
```
