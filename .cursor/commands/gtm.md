---
description: Create an actionable go-to-market playbook from strategy.md (.specs/gtm.md)
---

Create a go-to-market playbook for: $ARGUMENTS

## What This Command Does

`/gtm` turns strategy decisions into an actionable distribution plan. Strategy answers "who and why." GTM answers "where and how."

You are a **growth strategist, not a template filler.** Every recommendation must connect to the specific target customer, buying motion, and differentiation from strategy.md. Generic advice ("use content marketing") is worthless — be specific ("write a comparison post targeting people searching 'alternative to Competitor X' on Reddit").

```
/strategy → .specs/strategy.md (who we're selling to, how it makes money)
    ↓
/gtm → .specs/gtm.md (how we reach them, specific channels + actions)
    ↓
/find-early-users (find specific people and conversations right now)
```

---

## Prerequisites

**Required:** `.specs/strategy.md` must exist with real content (not just template). If it's missing or a stub, tell the user to run `/strategy` first.

**Optional but helpful:**
- `.specs/personas/*.md` — persona vocabulary shapes outreach messaging
- `.specs/vision.md` — product description helps position messaging

---

## Mode Detection

| Condition | Mode |
|-----------|------|
| No gtm.md or only template | **Create** — full playbook |
| gtm.md has real content | **Update** — revise based on new information or strategy changes |
| `--refresh` flag | **Refresh** — re-run research with current WebSearch data |

---

## Phase 1: Load Context

Read these in parallel:

1. `.specs/strategy.md` — target customer, buying motion, value prop, differentiation, anti-goals
2. `.specs/personas/*.md` — vocabulary, patience level, frustrations (if they exist)
3. `.specs/vision.md` — product description (if it exists)
4. `.specs/gtm.md` — existing playbook (if updating)

Extract and confirm:
- **Target customer**: [from strategy — specific role, company size, context]
- **Buying motion**: [from strategy — PLG, enterprise, self-serve, hybrid]
- **Value prop one-liner**: [from strategy]
- **Key differentiator**: [from strategy]
- **Anti-segment**: [who we're NOT targeting]

---

## Phase 2: Channel Research

Use WebSearch to find **current, specific** channels where the target customer is active. This is not generic advice — it's real research.

### Search strategy (run in parallel where possible):

**Reddit research:**
- Search: "[problem domain] site:reddit.com"
- Search: "[competitor name] alternative site:reddit.com"
- Search: "[target role] tools site:reddit.com"
- Find specific subreddits, note subscriber counts and activity level
- Find recent threads where people discuss the problem from strategy.md

**Twitter/X research:**
- Search: "[problem domain] OR [competitor] OR [industry term]"
- Find accounts that tweet about this problem space
- Find hashtags the target customer follows
- Look for people publicly complaining about competitors

**Community research:**
- Search: "[industry] community" or "[industry] slack" or "[industry] discord"
- Search: "[industry] newsletter" or "[industry] podcast"
- Find Indie Hackers, ProductHunt, HN threads on similar products
- Find relevant LinkedIn groups or communities

**Content/SEO research:**
- Search: "[problem] how to" or "[competitor] vs" or "[problem] tools"
- Identify high-intent search terms the target customer uses
- Find blogs, publications, or aggregators in the space

### For each channel found, capture:

```markdown
- **Channel**: [specific — e.g. "r/SaaS (45k members, 3-5 posts/day)"]
- **Why**: [how it connects to target customer]
- **Audience match**: High / Medium / Low
- **Effort**: Low / Medium / High
- **Example content**: [what a good post/message looks like there]
```

---

## Phase 3: Build the Playbook

Organize findings into a prioritized, actionable plan.

### Channel Ranking

Rank channels by: (audience match × low effort) first. The best early channels are where your target customer already hangs out AND you can participate without spending money.

### Messaging Framework

Derive from strategy + personas:

1. **Problem hook** — one sentence that makes the target customer nod ("Tired of spending 30 minutes on X every morning?")
2. **Solution tease** — what it does without jargon, in persona vocabulary
3. **Proof point** — specific claim ("cuts X from 30 min to 30 seconds")
4. **CTA** — what you want them to do (try it, give feedback, join waitlist)

Adapt this framework per channel:
- **Reddit**: Lead with the problem, share genuinely, link subtly. Never hard-sell.
- **Twitter/X**: Hook in first line, thread for details, visual if possible.
- **HN**: Technical depth, honest about trade-offs, Show HN format.
- **LinkedIn**: Professional framing, ROI-focused for enterprise buyers.
- **Email/DM**: Personal, reference something specific they said/wrote.

### Outreach Templates

Write 2-3 templates adapted to the channels identified:

1. **Community post** — for Reddit/HN/forums (value-first, not promotional)
2. **Cold DM** — for Twitter/LinkedIn (personal, references their specific pain)
3. **Feedback request** — for reaching out to potential early users

Each template should use persona vocabulary (if personas exist) and reference the specific value prop from strategy.

### Launch Timeline

Create a week-by-week plan for the first 30 days:

**Week 0 (Pre-launch):**
- [ ] Set up tracking (how will you know where users come from?)
- [ ] Join target communities, start participating (don't pitch yet)
- [ ] Draft all outreach templates

**Week 1-2 (Soft launch):**
- [ ] Reach out to [N] specific people for feedback (see `/find-early-users`)
- [ ] Post in [community 1] — value-first post about the problem
- [ ] Share in [community 2] — different angle

**Week 3-4 (Public launch):**
- [ ] ProductHunt / Show HN / launch post (if applicable to buying motion)
- [ ] Follow up with early feedback users
- [ ] Publish comparison content targeting "[competitor] alternative" searches

---

## Phase 4: Write gtm.md

Write `.specs/gtm.md`:

```markdown
# Go-to-Market Playbook

> [One-liner: how we're reaching our target customer]

**Last updated**: YYYY-MM-DD
**Strategy**: `.specs/strategy.md`

---

## Target Summary

(Pulled from strategy.md — keep it visible so the playbook stays grounded)

- **Customer**: [from strategy]
- **Buying motion**: [from strategy]
- **Value prop**: [from strategy]
- **Differentiator**: [from strategy]

## Channel Map

### Tier 1 — Start Here

| Channel | Audience Match | Effort | Status |
|---------|---------------|--------|--------|
| [e.g. r/SaaS] | High | Low | ⬜ Not started |
| [e.g. Twitter #hashtag] | High | Medium | ⬜ Not started |

**r/SaaS** (45k members)
- Why: [target customer is active here, posts about this problem weekly]
- What works: [problem-first posts, genuine discussion, no self-promo]
- Recent relevant threads: [links from research]
- Draft post: [template below]

**Twitter/X — @accounts and #hashtags**
- Why: [influencers in this space have engaged audiences]
- Key accounts: [@person1 (12k followers, tweets about X), @person2 ...]
- Hashtags: [#tag1, #tag2]
- Draft thread: [template below]

### Tier 2 — After First 10 Users

| Channel | Audience Match | Effort | Status |
|---------|---------------|--------|--------|
| [e.g. ProductHunt] | Medium | High | ⬜ Not started |

[Details for each...]

### Tier 3 — Scale Channels (Month 2+)

[SEO, content marketing, partnerships — things that take longer to pay off]

## Messaging

### Core Framework

- **Problem hook**: "[statement]"
- **Solution tease**: "[statement]"
- **Proof point**: "[statement]"
- **CTA**: "[statement]"

### Outreach Templates

#### Community Post (Reddit / Forums)

```
[Title that frames the problem, not the solution]

[2-3 sentences about the problem — use persona vocabulary]
[What you tried / built to solve it]
[Honest take — what works, what doesn't yet]
[Ask for feedback, not signups]
```

#### Cold DM (Twitter / LinkedIn)

```
Hey [name] — saw your [post/tweet/comment] about [specific thing].

[1 sentence connecting to their pain]
[1 sentence about what you're building]
[Ask: would you be open to trying it / giving feedback?]
```

#### Feedback Request

```
[For people who've expressed the problem publicly]

[Reference their specific complaint/post]
[What you're building to solve it]
[Specific ask: 15-min call, try the beta, fill out a form]
```

## Launch Timeline

### Week 0: Setup
- [ ] [action]
- [ ] [action]

### Week 1-2: Soft Launch
- [ ] [action]
- [ ] [action]

### Week 3-4: Public Launch
- [ ] [action]
- [ ] [action]

### Month 2: Scale
- [ ] [action]

## Metrics

| Metric | Week 1 | Week 4 | Month 2 |
|--------|--------|--------|---------|
| Conversations started | [target] | | |
| Feedback calls | [target] | | |
| Signups / waitlist | [target] | | |
| Active users | | [target] | |

## Research Log

[Raw findings from Phase 2 research — links, threads, accounts discovered]

### Reddit Threads
- [link] — [why relevant]

### Twitter Accounts
- [@handle] — [why relevant]

### Communities
- [community] — [why relevant]

### Content Opportunities
- "[search term]" — [volume/competition notes]
```

---

## After Saving

```
✅ GTM playbook saved to .specs/gtm.md

Channels identified:
- Tier 1: [channels] (start now)
- Tier 2: [channels] (after first 10 users)

Templates created:
- Community post, Cold DM, Feedback request

Next steps:
- Run /find-early-users to get a specific prospect list right now
- Start Week 0 actions from the launch timeline
- Review outreach templates and personalize them
```

---

## Update Mode

When gtm.md already exists:

1. Read current gtm.md
2. Read strategy.md (check if strategy has changed)
3. If strategy changed, flag sections of GTM that need revision
4. Ask what prompted the update — new channel discovered? Previous channel didn't work?
5. Re-run relevant research (not all channels, just the ones being revised)
6. Update with tracked changes

---

## Refresh Mode (`--refresh`)

Re-run all WebSearch research with fresh data:

1. Read current gtm.md for structure
2. Re-search all channels for new threads, new accounts, new communities
3. Update the Research Log with new findings
4. Flag any channels that have become more or less active
5. Update templates if persona vocabulary has changed

---

## Command Triggers

These phrases should invoke `/gtm`:

| User says | Action |
|-----------|--------|
| "gtm" | Run `/gtm` |
| "go to market" | Run `/gtm` |
| "GTM playbook" | Run `/gtm` |
| "marketing plan" | Run `/gtm` |
| "how do we get users" | Run `/gtm` |
| "distribution plan" | Run `/gtm` |
| "growth plan" | Run `/gtm` |
| "channel strategy" | Run `/gtm` |
| "launch plan" | Run `/gtm` |
| "outreach plan" | Run `/gtm` |
