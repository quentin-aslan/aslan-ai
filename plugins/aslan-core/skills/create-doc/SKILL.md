---
name: create-doc
description: Use when writing any standalone document (report, research writeup, README, spec, changelog) that a human and/or an AI will re-read later. Not for chat replies — this is for files that persist. Enforces a terse, scannable, ADHD-friendly, AI-parseable format.
---

# create-doc

A document is read under time pressure, skimmed, or re-parsed by an AI months later. Optimize
for that, not for prose quality.

## Rules

1. **Answer first.** Lead with the conclusion/result/number. Context and caveats come after, never
   before.
2. **No blabla.** Cut intros, transitions, "it's worth noting that", summary-of-what-follows. If a
   sentence doesn't add a fact or a decision, delete it.
3. **Bullets and tables over paragraphs.** A paragraph is only for something that genuinely doesn't
   decompose (a single nuanced explanation). Default to lists.
4. **Tables for anything with 2+ comparable items and 2+ attributes.** Rows = items, columns =
   attributes. Never describe in prose what a table would show in one glance.
5. **ASCII diagrams for structure, flow, or relationships** — file trees, pipelines, before/after,
   architecture. Only when it's actually faster to read than a sentence; don't decorate.
6. **Every claim sourced and dated** when the doc reports research/facts gathered externally: URL +
   date, or file path + line. A claim with no source is unusable to a future reader (human or AI)
   who needs to check it.
7. **Mark confidence explicitly** when not directly verified: `[REPORTED]`/`[UNVERIFIED]` vs
   `[VERIFIED]` (direct fetch/read behind it). Never silently present an unverified claim as fact.
8. **Headings are load-bearing.** Someone should be able to read only the headings + table
   headers and get the shape of the doc. Write headings as answers/topics, not vague labels
   ("Résultats" → "Coverage: 8 countries, 11 sources").
9. **Say "nothing found" explicitly** when a search/section came up empty — silence reads as "not
   checked," an explicit null result reads as "checked, no signal."
10. **One idea per line/bullet.** No compound bullets joining two unrelated facts with "and" — a
    reader/AI scanning for one fact shouldn't have to parse a sentence to extract it.

## Anti-patterns

| Don't | Do |
|---|---|
| "In this document, we will explore..." | Delete — start with the first real fact |
| Wall of prose describing a comparison | Table |
| "It seems that maybe X could possibly be..." | State the claim + `[UNVERIFIED]`, or don't state it |
| Burying the number/verdict in paragraph 3 | Put it in the first line or the heading |
| A 400-word section with no subheadings | Break into bullets/table or add subheadings |

## When to use an ASCII diagram

Good fit: file/folder trees, pipeline stages (`A → B → C`), before/after state, dependency
direction. Bad fit: anything that's really just a list — a table or bullets reads faster.

```
data/ (raw)  →  scripts/scan_*.py  →  01-marche/*.md  →  04-journal/YYYY-MM-DD.md
```

## Language

Match the target repo's existing convention (see the repo's own CLAUDE.md/README first). This
skill governs *shape*, not language choice.
