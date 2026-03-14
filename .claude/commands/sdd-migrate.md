---
description: Upgrade SDD to latest version (preserves custom commands/rules)
---

Upgrade this project's SDD installation to the latest version.

If `.sdd-upgrade/` doesn't exist yet, this command automatically runs `git auto-upgrade` to stage the files first.

## Prerequisite Checks

1. Check `.specs/` exists → if missing, error: "Not an SDD project, use 'git auto'"
2. Check `.sdd-upgrade/` exists → if missing, auto-stage by running `git auto-upgrade`. If that fails, error: "Failed to stage upgrade files. Check network and try 'git auto-upgrade' manually."
3. Read CURRENT version from `VERSION` or `.specs/.sdd-version` (default "1.0.0")
4. Read TARGET version from `.sdd-upgrade/VERSION` (default "2.1.0")
5. If TARGET > CURRENT → Proceed with upgrade (label: UPGRADE)
6. If TARGET = CURRENT → Proceed with re-sync (label: RE-SYNC). Even at the same version, files may have drifted from partial migrations or manual edits.
7. If TARGET < CURRENT → "Installed version is newer than template. Skipping."

## Stock vs Custom Detection

**Do NOT use hardcoded command lists.** Instead:
- Everything in `.sdd-upgrade/.cursor/commands/` = stock (sync these)
- Everything in `.sdd-upgrade/.cursor/rules/` = stock (sync these)
- Files in project's commands/rules NOT in staging = custom (preserve these)

## Upgrade Steps

1. **Inventory**: List commands/rules, classify as stock (in staging) or custom (not in staging)
2. **Directories**: Create `.specs/learnings/`, `.specs/design-system/components/`, `.specs/personas/`, `logs/` if missing
3. **Learnings**: Copy learnings templates with no-clobber (`cp -n`) — don't overwrite existing content
4. **Frontmatter**: Add YAML frontmatter to specs that don't have it (don't change content)
5. **Commands**: Copy ALL `.md` files from `.sdd-upgrade/.cursor/commands/` → `.cursor/commands/`. Same for `.claude/commands/` if staging has them.
6. **Rules**: Copy ALL `.mdc` files from `.sdd-upgrade/.cursor/rules/` → `.cursor/rules/`
7. **Hooks**: Copy `.cursor/hooks.json` and `hooks/` from staging
8. **Scripts**: `cp -r .sdd-upgrade/scripts .` + `chmod +x scripts/*.sh`
9. **CLAUDE.md**: Copy from staging
10. **Mapping**: Backup mapping.md, run `./scripts/generate-mapping.sh`
11. **Version**: Copy VERSION from staging, copy to `.specs/.sdd-version`
12. **Cleanup**: `rm -rf .sdd-upgrade`

## Frontmatter Format (for specs missing it)

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

Show inventory of stock vs custom files, execute steps, summarize what was synced vs preserved. If `.sdd-upgrade/CHANGELOG.md` exists, show what's new.
