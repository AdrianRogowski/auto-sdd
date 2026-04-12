---
description: Define business strategy and product positioning before building (.specs/strategy.md)
---

Shape the product strategy for: $ARGUMENTS

## What This Command Does

Product strategy sits upstream of everything. It answers "should we build this, and how does it become valuable?" before `/vision` answers "what does it do?" and `/spec-first` answers "how does it work?"

You are a **thinking partner, not a scribe.** Push for simplicity, surface trade-offs, question assumptions, and force decisions. Every recommendation should earn its place with evidence or reasoning.

```
/strategy → .specs/strategy.md
    ↓
/vision (reads strategy — now grounded in business decisions)
    ↓
/personas (reads strategy — determines WHO the personas are)
    ↓
/constitution (reads strategy — enterprise vs PLG changes constraints)
    ↓
/design-tokens → /roadmap → /spec-first → /tdd
```

---

## Mode Detection

| Condition | Mode |
|-----------|------|
| No strategy.md or only template | **Create** — full shaping conversation |
| strategy.md has real content | **Update** — revise based on new information |
| `--review` flag | **Review** — evaluate current strategy against progress |

---

## Phase 1: Frame the Problem

*Goal: define what we're solving and for whom, before deciding how.*

### If user provided a description

Use it as a starting point, but push on it. Don't accept the first framing.

### Ask and push on:

1. **What problem are we solving?** Not "what are we building" — what pain exists today?
2. **Who has this problem?** Be specific — job title, context, frequency of pain.
3. **How do they solve it today?** (The answer is never "they don't" — they use spreadsheets, email, manual processes, a competitor, or they just don't do it)
4. **What would make them switch?** From their current solution to this one.
5. **Who is paying?** The user and the buyer are often different people.

**Push back on vague answers:**
- "Everyone needs this" → "Who needs it most? Who would pay first?"
- "It's better than X" → "Better how? Faster? Cheaper? Simpler? For whom?"
- "We'll figure out monetization later" → "Even a rough model shapes what we build. Freemium? Per-seat? Usage-based?"

---

## Phase 2: Research (if applicable)

Once the problem is framed, propose a research plan. Not every project needs deep research — a weekend side project can skip this. But any product intended for real users benefits from even 30 minutes of structured research.

### Offer these research streams:

Let the user pick which matter. Use AskQuestion for multi-select if in an interactive context.

**Always available:**
- **Competitive landscape** — how do existing tools solve this? What's their pricing, positioning, weaknesses?
- **Codebase exploration** — what do we already have that's reusable?
- **Domain learning** — unfamiliar industry? Learn the vocabulary and workflows before designing.

**If the user has access to data sources:**
- **Customer/user evidence** — transcripts, interviews, support tickets, analytics
- **Internal knowledge** — wiki, Confluence, Slack threads, meeting notes
- **External API/docs review** — relevant third-party APIs, data sources, technical constraints

### Before researching, agree on keywords

The same concept has multiple names — customers, accounts, prospects, leads. Sales reps, account executives, SDRs. Agree on search terms before launching research.

### Execute research

Run research streams in parallel where possible. For each stream, capture:
- Key findings (bullet points, not essays)
- Implications for the product (what this means for what we build)
- Open questions raised

---

## Phase 3: Shape the Strategy

*Goal: converge on decisions through conversation.*

This is conversational, not template-driven. The shape emerges from iterating on the research.

### How shaping works

1. **Present research synthesis** as a starting point
2. **Ask pointed questions that force design decisions:**
   - "Should this be a standalone app or integrate into their existing workflow?"
   - "Are we selling to individual users or their managers?"
   - "Is this a tool they use daily or occasionally?"
3. **Surface competitive patterns** when relevant: "Competitor X does Y — which fits our constraints?"
4. **Track requirements** as they emerge. Ground each in evidence. Challenge any that can't be grounded.
5. **Track open questions** — things we need to validate that we can't answer yet.

### Key decisions to force:

**Target customer segment:**
- Individual contributor vs manager vs executive?
- Small team vs enterprise?
- Technical vs non-technical?

**Buying motion:**
- Bottom-up / PLG (individuals adopt, org upgrades later — Slack model)
- Top-down enterprise (sell to decision-maker, deploy to org)
- Self-serve (credit card, no sales team)
- Hybrid (self-serve for small, sales-assisted for large)

**Core value proposition:**
- What's the one sentence that makes someone try this?
- What's the "aha moment" — when do they first feel the value?

**Differentiation:**
- Why this and not the existing solutions?
- Is the moat speed, data, UX, integration, price, or something else?

**Business model intuition** (not a full financial model — just directional):
- How does this make money? (subscription, usage, freemium, marketplace)
- Rough price point? ($10/mo individual tool vs $200/seat/yr platform)
- What's the expansion path? (more seats, more features, higher tier)

### When multiple shapes emerge

Sometimes the conversation produces 2-3 distinct approaches. Capture them with a lightweight comparison:

```markdown
| | Shape A: Chrome Extension | Shape B: Platform |
|---|---|---|
| Target | Individual reps | VP Sales |
| Buying | Bottom-up, self-serve | Top-down, sales-assisted |
| Price | $15/mo per user | $200/seat/yr |
| Time to value | < 60 seconds | Weeks (onboarding) |
| Moat | UX speed | Data/integrations |
| Risk | Hard to monetize at scale | Long sales cycle |
```

Force a decision. Don't leave two shapes alive — pick one for v1. The other can be a future pivot.

---

## Phase 4: Write strategy.md

After decisions are made, write `.specs/strategy.md` with this structure:

```markdown
# Product Strategy

> [One sentence: what this is and why it matters]

**Last updated**: YYYY-MM-DD

---

## Problem

[2-3 sentences. What pain exists, who has it, how they cope today.]

## Target Customer

**Primary segment**: [Specific role/title, company size, context]
**Buyer**: [Who pays — same as user, or different?]
**Anti-segment**: [Who we're explicitly NOT building for in v1]

## Buying Motion

[Bottom-up PLG / Top-down enterprise / Self-serve / Hybrid]

[1-2 sentences on why this motion fits this customer and problem.]

## Value Proposition

**One-liner**: [The pitch — what it does and why it matters]
**Aha moment**: [When does the user first feel value?]
**Time to value**: [How long from signup to aha moment?]

## Differentiation

[Why this vs existing solutions. Be specific — not "better UX" but "prospect research in 10 seconds vs 15 minutes of manual Googling."]

## Business Model

**Revenue model**: [Subscription / Usage / Freemium+upgrade / etc.]
**Price intuition**: [Rough range, not exact — "$10-20/mo per user" or "enterprise contract $X/seat/yr"]
**Expansion path**: [How does revenue grow? More seats? Higher tier? New products?]

## Success Metrics

| Timeframe | Metric | Target |
|-----------|--------|--------|
| 1 month | [activation/engagement metric] | [target] |
| 6 months | [retention/growth metric] | [target] |
| 12 months | [revenue/scale metric] | [target] |

## Anti-Goals

[What we're explicitly NOT doing in v1. These prevent scope creep.]

- [Anti-goal 1 — and why it's tempting but wrong for now]
- [Anti-goal 2]

## Open Questions

[Things we believe but haven't validated. Each should have a plan to validate.]

- [ ] [Question 1] — validate by: [method]
- [ ] [Question 2] — validate by: [method]

## Research Summary

[If Phase 2 research was done, summarize key findings here. Keep it brief — bullets, not essays.]

### Competitive Landscape
- [Competitor 1]: [positioning, price, weakness]
- [Competitor 2]: [positioning, price, weakness]

### Key Insights
- [Insight that shaped a decision]
- [Insight that shaped a decision]
```

---

## Phase 5: GTM Sketch

*Goal: bridge strategy to action. Don't just document who we're selling to — sketch how to reach them.*

This phase runs automatically after saving strategy.md. It adds a `## GTM Sketch` section to the bottom of strategy.md. Keep it lightweight — `/gtm` will expand it into a full playbook.

### Based on buying motion, suggest channels:

**Bottom-up / PLG:**
- Developer communities (Reddit, HN, Dev.to, specific subreddits)
- Twitter/X (developer influencers, hashtags)
- Open source / free tier as acquisition channel
- Content marketing (blog posts solving the pain from Phase 1)
- ProductHunt / Show HN launch

**Top-down enterprise:**
- LinkedIn outreach to decision-makers
- Industry conferences and events
- Case studies and ROI calculators
- Partner/integration ecosystem
- Warm introductions via investors/advisors

**Self-serve:**
- SEO for problem-keyword searches
- Comparison pages (vs Competitor X)
- Integration marketplaces (Zapier, app stores)
- Affiliate/referral programs

**Hybrid:**
- Combine PLG acquisition with sales-assisted expansion
- Community-led growth → enterprise upsell

### For each recommended channel, provide:

1. **Why this channel** — one sentence connecting it to the target customer from Phase 1
2. **Where specifically** — not "Reddit" but "r/SaaS, r/startups, r/[industry]"; not "Twitter" but "@specific_accounts, #specific_hashtags"
3. **What to say** — a draft message/post tailored to persona vocabulary (if personas exist)

### Add to strategy.md:

```markdown
## GTM Sketch

**Primary channels** (start here):
1. [Channel] — [why, where specifically]
2. [Channel] — [why, where specifically]

**Secondary channels** (after first 10 users):
3. [Channel] — [why, where specifically]

**First 10 users plan**:
- [ ] [Specific action 1 — e.g. "Post in r/SaaS asking for feedback on the problem"]
- [ ] [Specific action 2 — e.g. "DM 5 people who complained about X in this thread: [link]"]
- [ ] [Specific action 3]

> Run `/gtm` for a full playbook with templates, timeline, and community map.
> Run `/find-early-users` to search for specific people and conversations right now.
```

---

## After Saving

Show the strategy summary and recommend next steps:

```
✅ Strategy saved to .specs/strategy.md

Key decisions:
- Target: [segment]
- Motion: [buying motion]
- Model: [revenue model]
- Differentiator: [key differentiator]

GTM sketch:
- Primary channels: [channels]
- First 10 users: [plan summary]

Next steps:
- Run /vision to define the product (will read strategy.md)
- Run /personas to define users (will read strategy.md)
- Run /roadmap to plan features (will read strategy.md)
- Run /gtm for a full go-to-market playbook
- Run /find-early-users to find specific people to talk to right now
```

---

## Update Mode

When strategy.md already exists:

1. Read current strategy.md
2. Read `.specs/roadmap.md` for what's been built
3. Read `.specs/learnings/index.md` for what's been learned
4. Ask what prompted the update — new information? Pivot? Market change?
5. Surface what the current strategy says vs what reality shows
6. Update with tracked changes — note what changed and why

---

## Review Mode (`--review`)

Evaluate current strategy against actual progress:

1. Read strategy.md, roadmap.md, vision.md, learnings/
2. Report alignment:
   - Are we building for the stated target customer?
   - Does the feature set match the buying motion?
   - Are anti-goals being respected?
   - Have open questions been answered?
3. Flag drift: "Strategy says PLG but 4 of your last 6 features are admin/enterprise features"
4. Recommend: update strategy, reprioritize roadmap, or stay the course

---

## When to Skip This

Not every project needs a strategy document:
- **Internal tools**: The "customer" is your team. Skip to `/vision`.
- **Learning projects**: You're exploring a technology. Skip to `/spec-first`.
- **Prototypes**: You're testing feasibility. Use `/prototype`.

If the user's project clearly doesn't need strategy (side project, internal tool, learning exercise), say so and suggest skipping to `/vision` instead.

---

## Command Triggers

These phrases should invoke `/strategy`:

| User says | Action |
|-----------|--------|
| "strategy" | Run `/strategy` |
| "product strategy" | Run `/strategy` |
| "business strategy" | Run `/strategy` |
| "shape this" | Run `/strategy` |
| "who are we selling to" | Run `/strategy` |
| "business model" | Run `/strategy` |
