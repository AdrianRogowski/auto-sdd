---
description: Migrate from SDD 1.0 to SDD 2.0 with compound learning and automation
---

Upgrade this project from SDD 1.0 to SDD 2.0.

## Detection

1. Check `.specs/.sdd-version` - if exists, read version
2. If no version file but `.specs/` exists → SDD 1.0
3. If no `.specs/` → not an SDD project, suggest `git auto`

## Migration (1.0 → 2.0)

1. **Create learnings folder**: `.specs/learnings/` with index.md + 6 category files
2. **Add YAML frontmatter** to existing feature specs
3. **Update commands**: Replace all, add `compound.md`
4. **Update rules**: Replace all, add `compound.mdc`
5. **Add hooks**: `hooks.json` + hook scripts
6. **Add scripts**: Automation scripts in `scripts/`
7. **Regenerate mapping.md**: Run `./scripts/generate-mapping.sh`
8. **Update CLAUDE.md**: SDD 2.0 version
9. **Create version file**: `.specs/.sdd-version` = 2.0

## YAML Frontmatter Format

Add to top of each existing feature spec:

```yaml
---
feature: {name from # header}
domain: {from file path}
source: {from Source File line or empty}
tests: []
components: []
design_refs: []
status: implemented
created: {today}
updated: {today}
---
```

## Output

Show migration plan, ask for confirmation, then execute and summarize changes.
