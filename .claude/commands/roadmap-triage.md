# Roadmap Triage

Scan Slack and Jira for feature requests and add them to the roadmap.

## Usage

```
/roadmap-triage
/roadmap-triage --slack-only
/roadmap-triage --jira-only
```

---

## What This Command Does

1. **Scan** - Search Slack channel and Jira for feature requests
2. **Filter** - Skip items already in roadmap or marked as handled
3. **Add** - Add new items to roadmap.md "Ad-hoc Requests" section
4. **Create** - Optionally create Jira tickets for Slack items
5. **Mark** - Mark source items as triaged

---

## Step 1: Load Configuration

Read from `.env.local`:

```bash
# Slack
SLACK_FEATURE_CHANNEL="#feature-requests"
SLACK_SEARCH_KEYWORDS="feature request,can we add,would be nice"
SLACK_LOOKBACK_DAYS=7

# Jira
JIRA_CLOUD_ID="yoursite.atlassian.net"
JIRA_PROJECT_KEY="PROJ"
JIRA_AUTO_LABEL="auto-ok"

# Options
CREATE_JIRA_FOR_SLACK=true
```

---

## Step 2: Scan Slack

Search for feature requests in the configured channel:

```
CallMcpTool("user-slack", "conversations_search_messages", {
  filter_in_channel: "[SLACK_FEATURE_CHANNEL]",
  filter_date_after: "[LOOKBACK_DAYS ago]",
  search_query: "[SLACK_SEARCH_KEYWORDS]",
  limit: 20
})
```

### Filter Slack Results

Skip messages that:
- Already have a triaged reply (contains "👀" or "✅")
- Are already in roadmap.md (check source column for `slack:CHANNEL/TS`)
- Are bot messages
- Are thread replies (handle parent only)

### Extract from Slack

For each valid message:
```json
{
  "source": "slack:C123ABC/1234567890.123456",
  "summary": "[extracted feature description]",
  "requester": "@username",
  "date": "2024-01-15"
}
```

---

## Step 3: Scan Jira

Search for auto-approved tickets:

```
CallMcpTool("user-atlassian", "searchJiraIssuesUsingJql", {
  cloudId: "[JIRA_CLOUD_ID]",
  jql: "project = [PROJECT_KEY] AND labels = '[AUTO_LABEL]' AND status = 'To Do'",
  fields: ["summary", "description", "key", "created"]
})
```

### Filter Jira Results

Skip issues that:
- Are already in roadmap.md (check Jira column)
- Have been transitioned out of "To Do"

### Extract from Jira

For each valid issue:
```json
{
  "source": "jira:[KEY]",
  "jira": "[KEY]",
  "summary": "[issue summary]",
  "description": "[issue description]",
  "date": "[created date]"
}
```

---

## Step 4: Add to Roadmap

For each new item, add to the "Ad-hoc Requests" section of `.specs/roadmap.md`:

```markdown
## Ad-hoc Requests

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 100 | Export to CSV | slack:C123/1234.56 | PROJ-200 | S | - | ⬜ |
| 101 | Dark mode toggle | jira:PROJ-456 | PROJ-456 | M | - | ⬜ |
```

### Assign Feature Numbers

- Ad-hoc features start at #100
- Increment from highest existing number in Ad-hoc section

### Estimate Complexity

Based on description, estimate:
- **S**: Simple UI change, single component
- **M**: Multiple components, some logic
- **L**: Full feature, API changes

Default to **M** if unclear.

### Identify Dependencies

Check if the feature likely depends on existing roadmap items:
- References "dashboard" → probably depends on Dashboard feature
- References "user data" → probably depends on Auth features

Default to `-` (no deps) if unclear.

---

## Step 5: Create Jira Tickets (for Slack items)

If `CREATE_JIRA_FOR_SLACK=true` and item came from Slack:

```
CallMcpTool("user-atlassian", "createJiraIssue", {
  cloudId: "[JIRA_CLOUD_ID]",
  projectKey: "[JIRA_PROJECT_KEY]",
  issueTypeName: "Story",
  summary: "[feature summary]",
  description: "**Source**: Slack message from @[requester]\n**Channel**: [channel]\n**Date**: [date]\n\n---\n\n[original message content]"
})
```

Update roadmap entry with new Jira key.

---

## Step 6: Mark Sources as Triaged

### Slack

Reply to the message thread:

```
CallMcpTool("user-slack", "conversations_add_message", {
  channel_id: "[CHANNEL_ID]",
  thread_ts: "[MESSAGE_TS]",
  payload: "👀 Added to roadmap!\n\nTicket: [JIRA_KEY]\nRoadmap item: #[FEATURE_NUMBER]\n\nThis will be picked up by automation or you can track progress in Jira."
})
```

### Jira

Add a comment:

```
CallMcpTool("user-atlassian", "addCommentToJiraIssue", {
  cloudId: "[JIRA_CLOUD_ID]",
  issueIdOrKey: "[JIRA_KEY]",
  commentBody: "👀 Added to roadmap!\n\nRoadmap item: #[FEATURE_NUMBER]\n\nThis will be picked up by /build-next automation."
})
```

---

## Step 7: Update Progress Summary

Update the counts in roadmap.md:

```markdown
## Progress

| Status | Count |
|--------|-------|
| ✅ Completed | [count] |
| 🔄 In Progress | [count] |
| ⬜ Pending | [count + new items] |
| ⏸️ Blocked | [count] |

**Last updated**: [current timestamp]
```

---

## Step 8: Commit Changes

```bash
git add .specs/roadmap.md
git commit -m "chore: triage [N] feature requests from Slack/Jira"
```

---

## Step 9: Report

```
✅ Triage complete!

Found:
- Slack: 3 new requests
- Jira: 2 new tickets

Added to roadmap:
| # | Feature | Source | Jira |
|---|---------|--------|------|
| 100 | Export to CSV | slack | PROJ-200 |
| 101 | Dark mode | slack | PROJ-201 |
| 102 | API rate limiting | jira | PROJ-150 |
| 103 | Mobile nav fix | jira | PROJ-151 |
| 104 | Bulk delete | slack | PROJ-202 |

Roadmap now has 23 total features (18 planned + 5 ad-hoc)

Run /build-next to start building!
```

---

## Running Automatically

This command is called by `overnight-autonomous.sh` before `/build-next`:

```bash
# In overnight-autonomous.sh:

# Step 1: Triage new requests
agent -p --force "/roadmap-triage"

# Step 2: Build from roadmap
for i in $(seq 1 $MAX_FEATURES); do
  agent -p --force "/build-next"
done
```

---

## Configuration Reference

Full `.env.local` options:

```bash
# ─────────────────────────────────────
# Slack Configuration
# ─────────────────────────────────────
SLACK_FEATURE_CHANNEL="#feature-requests"
SLACK_SEARCH_KEYWORDS="feature request,can we add,would be nice,bug,improvement"
SLACK_LOOKBACK_DAYS=7
SLACK_REPORT_CHANNEL="#dev-updates"

# ─────────────────────────────────────
# Jira Configuration
# ─────────────────────────────────────
JIRA_CLOUD_ID="yoursite.atlassian.net"
JIRA_PROJECT_KEY="PROJ"
JIRA_AUTO_LABEL="auto-ok"
JIRA_ISSUE_TYPE="Story"

# ─────────────────────────────────────
# Integration Options
# ─────────────────────────────────────
CREATE_JIRA_FOR_SLACK=true      # Create Jira tickets for Slack requests
SYNC_JIRA_STATUS=true           # Update Jira status when building
SLACK_NOTIFY_COMPLETE=true      # Reply to Slack when feature done
```
