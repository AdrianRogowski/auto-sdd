---
description: Find specific people, companies, and conversations to reach out to for early feedback
---

Find early users for: $ARGUMENTS

## What This Command Does

`/find-early-users` is the most concrete command in the GTM pipeline. It doesn't write plans — it finds **actual people and conversations** you can reach out to today.

It reads your strategy (who has this problem?) and searches the live web for people who are:
- Publicly complaining about the problem you're solving
- Asking for alternatives to competitors
- Discussing workflows that your product improves
- Building in adjacent spaces (potential partners/integrators)

**Output:** A prospect list with links, context, and draft messages — saved to `.specs/gtm/prospects.md`.

```
/strategy → who has this problem?
    ↓
/gtm → where do they hang out?
    ↓
/find-early-users → HERE ARE 10 SPECIFIC PEOPLE (with links and draft DMs)
```

---

## Prerequisites

**Required:** `.specs/strategy.md` must exist with real content. The command needs:
- Problem statement (what pain to search for)
- Target customer (who to look for)
- Differentiation (what makes this worth switching)

**Optional but helpful:**
- `.specs/gtm.md` — channels already identified (focuses the search)
- `.specs/personas/*.md` — vocabulary for draft messages
- Competitor names from strategy.md's research summary

If strategy.md is missing or a stub, tell the user to run `/strategy` first.

---

## Mode Detection

| Condition | Mode |
|-----------|------|
| No prospects.md | **Create** — full research sweep |
| prospects.md exists | **Update** — find new prospects, mark stale ones |
| `--channel [channel]` | **Focused** — search only one channel deeply |
| User provides a topic/keyword | Override search terms from strategy |

---

## Phase 1: Extract Search Intelligence

Read `.specs/strategy.md` and extract:

1. **Problem keywords** — the pain in the user's words (not developer jargon)
2. **Target role/title** — who has this problem (job title, context)
3. **Competitor names** — from competitive landscape section
4. **Industry terms** — domain-specific vocabulary
5. **Anti-segment** — who NOT to target (saves time filtering)

If personas exist, also extract:
- Vocabulary differences (their words vs our words)
- Frustration patterns (what they complain about)

If gtm.md exists, read the channel map to focus search on identified channels.

### Build search queries

Construct multiple search queries from the intelligence above. Good queries combine:
- Problem + platform: "[problem] site:reddit.com"
- Competitor complaints: "[competitor] frustrating OR annoying OR alternative OR switching"
- Role + pain: "[job title] [pain point] tools"
- Alternative seeking: "looking for [competitor] alternative"
- Workflow discussion: "how do you [workflow this product improves]"

---

## Phase 2: Research Sweep

Use WebSearch to execute searches. Run multiple searches in parallel where possible.

### Reddit Deep Dive

Search for:
1. **Problem threads** — people describing the exact pain from strategy.md
2. **Competitor threads** — "What do you use for X?" or "[Competitor] sucks" or "alternative to [Competitor]"
3. **Workflow threads** — people describing the manual process your product automates
4. **Advice threads** — "[role] here, how do you handle [problem]?"

For each relevant thread found, capture:
- **URL** — direct link to the thread
- **Date** — how recent (prefer last 6 months; older threads = the person may have moved on)
- **Author** — username (check their profile: are they the target customer?)
- **Pain signal** — the specific complaint or question they expressed
- **Engagement** — upvotes, comments (higher = more people share this pain)
- **Reachability** — can you reply in-thread? DM them? Is the thread locked?

### Twitter/X Deep Dive

Search for:
1. **Complaint tweets** — people frustrated with current solutions
2. **Question tweets** — "Anyone know a good tool for X?"
3. **Influencer takes** — thought leaders discussing the problem space
4. **Competitor mentions** — people tagging competitors with complaints

For each relevant account/tweet:
- **URL** — direct link to tweet
- **Account** — handle, follower count, bio (are they the target customer?)
- **Pain signal** — what they said
- **Engagement** — likes, replies, retweets
- **Reachability** — do they accept DMs? Are they active?

### Hacker News / Indie Hackers / Dev Communities

Search for:
1. **Show HN / Ask HN** threads about similar problems
2. **Comment threads** where people discuss the workflow
3. **Indie Hackers posts** from people building in adjacent spaces

### Company/Product Research

Search for:
1. **G2/Capterra reviews** of competitors (especially 2-3 star reviews — they use it but hate parts)
2. **Companies using competitors** (from case studies, integration pages, "powered by" footers)
3. **Job postings** that mention the problem ("looking for someone to manage [thing your product automates]")
4. **Blog posts** from companies describing the pain

### LinkedIn (if relevant to buying motion)

Search for:
1. **Posts about the problem** by people with the target job title
2. **Company pages** of potential customers
3. **Group discussions** in industry-specific LinkedIn groups

---

## Phase 3: Score and Rank Prospects

For each prospect found, score on:

| Factor | Weight | Description |
|--------|--------|-------------|
| **Recency** | High | Posted in last 3 months > 6 months > older |
| **Pain intensity** | High | Explicit frustration > mild curiosity |
| **Role match** | High | Exact target persona > adjacent role |
| **Reachability** | Medium | Can DM/reply directly > need to find contact info |
| **Influence** | Low | Large following is a bonus, not a requirement |

Sort prospects by score. The goal is the **warmest leads first** — people who recently expressed the exact pain and are reachable.

---

## Phase 4: Draft Outreach

For the top prospects, draft personalized messages. Each message must:

1. **Reference something specific they said** — proves you're not spamming
2. **Connect to the pain** — in their words, not yours
3. **Be honest about stage** — "I'm building something to solve this" not "We're the #1 solution"
4. **Ask for feedback, not a sale** — "Would you try this?" or "Am I thinking about this right?"
5. **Be brief** — 3-5 sentences max

### Per-channel message style:

**Reddit reply:**
- Contribute to the discussion first (answer their question, share insight)
- Mention your project naturally ("I'm actually building something for this")
- Don't link-drop — offer to share if they're interested

**Twitter DM:**
- Reference their specific tweet
- One sentence of context
- Clear ask (try it, 15-min call, feedback)

**Email / LinkedIn:**
- Professional but human
- Reference their company/role/post
- Specific value prop for their situation
- Easy out ("No worries if not — just thought it might be relevant")

---

## Phase 5: Write prospects.md

Create `.specs/gtm/` directory if it doesn't exist. Write `.specs/gtm/prospects.md`:

```markdown
# Early User Prospects

> Found by `/find-early-users` on YYYY-MM-DD
> Strategy: `.specs/strategy.md`

**Search queries used:**
- "[query 1]"
- "[query 2]"
- "[query 3]"

---

## Hot Prospects (reach out this week)

### 1. [Username/Name] — [Platform]

- **Link**: [URL to their post/tweet/comment]
- **Date**: [when they posted]
- **Pain signal**: "[what they said, quoted]"
- **Role match**: [how they match the target customer]
- **Reachability**: [DM open / can reply in thread / need email]

**Draft message:**
> [Personalized outreach message]

**Status**: ⬜ Not contacted

---

### 2. [Username/Name] — [Platform]

[Same format...]

---

## Warm Prospects (good fit, less urgent)

### 3. [Username/Name] — [Platform]

[Same format but lower urgency — older posts, less explicit pain]

---

## Threads to Monitor

These threads are active discussions where your target customer hangs out. Participate genuinely, don't pitch.

| Thread | Platform | Topic | Last Active |
|--------|----------|-------|-------------|
| [link] | Reddit | [topic] | [date] |
| [link] | Twitter | [topic] | [date] |

## Communities to Join

| Community | Platform | Members | Relevance |
|-----------|----------|---------|-----------|
| [name/link] | [Slack/Discord/Reddit] | [count] | [why] |

## Companies Using Competitors

| Company | Competitor | Evidence | Contact Angle |
|---------|-----------|----------|---------------|
| [company] | [competitor] | [how you know — review, case study, job post] | [approach] |

---

## Search Log

Raw search results for future reference. Re-run `/find-early-users` to refresh.

### Queries → Results
- "[query]" → [N results, top finding]
- "[query]" → [N results, top finding]
```

---

## After Saving

```
✅ Prospect list saved to .specs/gtm/prospects.md

Found:
- [N] hot prospects (reach out this week)
- [N] warm prospects (follow up later)
- [N] threads to monitor
- [N] communities to join
- [N] companies using competitors

Top 3 to contact first:
1. [Name] on [platform] — "[their pain signal]"
2. [Name] on [platform] — "[their pain signal]"
3. [Name] on [platform] — "[their pain signal]"

Draft messages are ready — review and personalize before sending.
```

---

## Update Mode

When prospects.md already exists:

1. Read current prospects.md
2. Check status of existing prospects (contacted? responded? stale?)
3. Re-run searches for new prospects
4. Add new finds, mark old ones as stale if their threads are > 3 months old
5. Move "warm" prospects up if new pain signals appear

---

## Focused Mode (`--channel [channel]`)

Search only one channel deeply:
- `--channel reddit` — deep Reddit research only
- `--channel twitter` — deep Twitter/X research only
- `--channel linkedin` — deep LinkedIn research only
- `--channel hn` — Hacker News focus

Useful when you know where your audience is and want more depth.

---

## Ethical Guardrails

This command finds people who have **publicly expressed** a problem. It does NOT:
- Scrape private information
- Build mass email lists
- Generate spam
- Fake engagement or identity

Every outreach draft is:
- Personalized (references something specific they said)
- Honest about what you're building and its stage
- Asking for feedback, not demanding attention
- Easy to ignore (no guilt, no follow-up pressure)

The goal is to **start conversations with people who want to be found**, not to cold-blast strangers.

---

## Command Triggers

These phrases should invoke `/find-early-users`:

| User says | Action |
|-----------|--------|
| "find early users" | Run `/find-early-users` |
| "find users" | Run `/find-early-users` |
| "find prospects" | Run `/find-early-users` |
| "find people" | Run `/find-early-users` |
| "who should I talk to" | Run `/find-early-users` |
| "find beta testers" | Run `/find-early-users` |
| "find feedback" | Run `/find-early-users` |
| "prospect list" | Run `/find-early-users` |
| "who's complaining about" | Run `/find-early-users` |
| "find my first users" | Run `/find-early-users` |
