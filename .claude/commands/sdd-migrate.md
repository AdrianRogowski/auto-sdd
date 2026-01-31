---
description: Migrate from SDD 1.0 to SDD 2.0 (preserves custom commands)
---

Upgrade this project from SDD 1.0 to SDD 2.0.

**Prerequisites**: Run `git auto-upgrade` first to stage 2.0 files in `.sdd-upgrade/`.

## Prerequisite Checks

1. Check `.sdd-upgrade/` exists → if missing, error: "Run 'git auto-upgrade' first"
2. Check `.specs/` exists → if missing, error: "Not an SDD project, use 'git auto'"
3. Check `.specs/.sdd-version` → if "2.0", already migrated

## Stock Commands (safe to replace)

```
catch-drift, check-coverage, code-review, design-component,
design-tokens, document-code, fix-bug, formalize, prototype,
refactor, spec-first, spec-init, start-feature, update-test-docs,
verify-test-counts
```

Any other commands are CUSTOM → preserve them.

## Migration Steps

1. **Inventory**: List commands/rules, identify stock vs custom
2. **Learnings**: `cp -r .sdd-upgrade/.specs/learnings .specs/learnings`
3. **Frontmatter**: Add YAML frontmatter to specs that don't have it (don't change content)
4. **Commands**: Copy stock commands from `.sdd-upgrade/.cursor/commands/`
5. **Rules**: Copy stock rules from `.sdd-upgrade/.cursor/rules/`, add compound.mdc
6. **Hooks**: Copy `.sdd-upgrade/.cursor/hooks.json` and hooks/ if not exist
7. **Scripts**: `cp -r .sdd-upgrade/scripts .`
8. **Mapping**: Backup mapping.md, run `./scripts/generate-mapping.sh`
9. **CLAUDE.md**: Copy from staging
10. **Version**: `echo "2.0" > .specs/.sdd-version`
11. **Cleanup**: `rm -rf .sdd-upgrade`

## Frontmatter Format

Add to specs missing it:

```yaml
---
feature: {from # header}
domain: {from path}
source: {from Source File line}
tests: []
components: []
status: implemented
created: {today}
updated: {today}
---
```

## Output

Show inventory, execute steps, summarize what was updated vs preserved, list new capabilities.
