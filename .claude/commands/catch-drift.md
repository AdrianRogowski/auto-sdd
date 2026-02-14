---
description: Detect when specs and code have diverged, then reconcile
---

Check for drift: $ARGUMENTS

## Scope

- Specific feature: Check one spec against implementation
- Component: Check all specs for a component
- Full audit: Check all specs (may take a while)

## Process

### 1. Compare Spec vs Code

For each Gherkin scenario:
- Find corresponding code path
- Verify behavior matches
- Check if test exists and passes

### 2. Report Categories

- **Matched** ✅: Spec, code, and tests agree
- **Spec Drift** ⚠️: Code does something different than spec says
- **Code Drift** ⚠️: Code does extra things not in spec
- **Missing Test** ❓: Behavior exists but no test
- **Broken Test** 🚩: Test fails

### 3. Reconcile

For each drift, ask:
- "Update spec to match code?" (document the change)
- "Update code to match spec?" (fix regression)
- "This is intentional, update both?"

### 4. Update Artifacts

After reconciliation:
- Update feature spec if needed
- Update or add tests
- Update test suite documentation
- Update mapping.md

## Output

Drift report with specific discrepancies, line numbers, and suggestions.

## Automated Mode (Build Loop)

When invoked by build scripts, auto-fix drift without asking (update specs to match code).

### Signal Protocol

Output EXACTLY ONE at the end:

- `NO_DRIFT` — spec and code are aligned
- `DRIFT_FIXED: {summary}` — drift found and auto-reconciled
- `DRIFT_UNRESOLVABLE: {reason}` — needs human decision

### Input Format

Build loop provides: `Spec file: {path}` and `Source files: {paths}`. Read only those files.
