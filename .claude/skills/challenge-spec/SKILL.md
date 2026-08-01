---
name: challenge-spec
description: Use to generate a critical adversarial review prompt targeting an implementation spec, plan, design doc, or RFC produced by another LLM (Claude, Codex, GPT, etc.). The output is a copy-paste prompt that forces a second LLM into adversarial posture — hunting for invented APIs, schema mismatches with the real codebase, race conditions, state-machine inconsistencies, stale cross-version content, V2-deferrals that should be V1, allowlist/denylist confusions, HTTP-under-lock anti-patterns, recovery paths that create new bugs, and other failure modes typical of LLM-generated artifacts. Invoke BEFORE implementing anything based on an LLM-produced artifact, and at every revision (re-running the same review on a revised spec routinely finds novel issues).
---

# challenge-spec — Adversarial review prompt for LLM-generated specs

## When to invoke

Use this skill whenever you receive an implementation artifact (spec, plan, design doc, RFC, architecture proposal) produced by another LLM **and** you intend to act on it (implement, merge, deploy). High-value cases:

- The artifact claims to integrate with an **external API** (LLMs hallucinate endpoint signatures, response field names, filter parameters with confidence).
- The artifact touches **DB schema, transactions, or concurrency**.
- The artifact defines a **state machine or status graph**.
- The artifact includes **recovery / crash-handling / boot-reconcile** logic.
- The artifact has been revised through **multiple passes** and you want a fresh independent pass.
- You want to use a **different LLM** to review what the first LLM wrote (most effective when the reviewer is a different model family).

Skip only when the artifact is trivial (< 50 lines, no external deps, no state, no schema).

## Battle-tested pattern

This skill was distilled from a real session (Gelato backend integration, May 2026) where 6 successive review passes on the same evolving spec found 50+ distinct issues — each pass surfacing novel bugs that all previous reviewers had missed. The 15 failure patterns below are the categories that produced the highest hit rate.

## Protocol (when the agent loads this skill)

1. **Collect inputs from the user** (ask if not already provided in context) :
   - `ARTIFACT` — path to the spec/plan, or pasted content, or git ref.
   - `CODEBASE_CONTEXT` — 1-3 sentences: tech stack, key conventions, where to grep.
   - `EXTERNAL_DEPS` — list of external APIs / services touched, with links to official docs or local skill memory files (e.g. `.claude/skills/<api>-dev/`).
   - `PRIOR_PASSES` (optional) — list of prior review iterations, used to focus on novel issues rather than addressed ones.

2. **Substitute** the placeholders in the template below with the user's inputs.

3. **Output** the customized prompt as a single fenced code block the user copies into their target LLM session (Claude.ai, Codex, GPT, code-reviewer subagent, etc.). Do NOT execute the review yourself unless explicitly asked.

4. **Remind** the user of the meta-tips at the bottom (different LLM than author, one pass at a time, resist defending).

## Prompt template (substitute placeholders before outputting)

````
You are doing an adversarial review of a spec/plan produced by another LLM.
Your job is to FIND FLAWS, not to validate. Reviews that find nothing are
reviews that failed to look hard enough. LLM-generated specs hallucinate
APIs, mismatch the real codebase, and gloss over concurrency. Assume the
artifact has bugs; your job is to surface them with concrete evidence.

# Artifact under review

{ARTIFACT}

# Codebase context

{CODEBASE_CONTEXT}

# External dependencies the artifact touches

{EXTERNAL_DEPS}

# Prior review passes (focus on NOVEL issues, not regressions)

{PRIOR_PASSES}

# Your protocol

1. **Read the artifact entirely first.** Do not skim. Multi-cluster specs
   often contradict themselves across sections; you must hold the full
   picture before judging any part.

2. **Cross-reference the real codebase** for every claim about existing
   code: file paths, function names, schema column names, API routes,
   fixture names, library imports. If the artifact says "the `foo` column
   on `bar` table", grep the actual table definition. If it says
   "import `respx`", check `requirements.txt`.

3. **Cross-reference external API docs** for every claim about an external
   service. Specs hallucinate endpoint signatures, response field names,
   and filter parameters constantly. If the artifact says
   "POST /v4/orders:search with filter `order_reference_ids`", verify in
   the official docs or skill memory.

4. **Compute invariants** for every claim involving time, retries, leases,
   or counts. "Lease = 90s" with "3 attempts × 30s timeout + 7s of
   backoff" = invariant violated (97s > 90s).

5. **Walk every crash window step by step.** For each "if process dies
   here, recovery does X": ask whether the remote state at that moment
   would lead recovery to the correct decision. Crash-after-success often
   gets mapped to failure by naive recovery.

6. **Cite file:line evidence** for every finding. Vague accusations
   ("this section seems unclear") are not findings. "Line 482: this UPDATE
   happens inside a transaction that wraps the HTTP call on line 489" is
   a finding.

7. **Categorize each finding** as Blocker / Important / Minor / Stale.

# 15 failure patterns to hunt explicitly

The artifact almost certainly contains some of these. Search for each:

1. **Invented API endpoints or parameters.** LLM-confident URLs that don't
   exist (`GET /v4/orders?orderReferenceIds[]=`). Response field names
   that don't match the real schema (`totalWidth` vs `bleedSize.width`).
   Filter parameter names that mix snake_case and camelCase inconsistently
   with the actual API.

2. **Schema mismatches with the real codebase.** Claimed columns /
   relations / methods that don't exist or have different names
   (`OrderItem.pdf_job` when the model has `OrderItem.pdf_jobs` plural).
   Foreign key types that don't match (String(36) vs UUID vs String(80)).
   Constants that don't exist in the cited module.

3. **Made-up test infrastructure.** References to fixtures, factories,
   pytest plugins, or libraries that aren't in the project (e.g. `respx`
   when only `httpx.MockTransport` is available). Imaginary
   `client_with_user`, `paid_order_factory` etc. that never get defined.

4. **HTTP calls inside DB transactions or locks.** Anti-pattern. Look for
   `with db.transaction()`, `SELECT ... FOR UPDATE`, or open SQLAlchemy
   sessions surrounding `await client.post()` / `requests.get()`. The
   transaction is held for the duration of the network call, multiplied
   by retries.

5. **Cache that prevents the audit it should enable.** A "drift assertion"
   that reads from a cache and so by construction cannot detect drift.
   The audit path must bypass the cache (force live fetch) even when the
   render/perf path uses it.

6. **State-machine inconsistencies across versions.** Earlier sections
   claim `A → B`, later sections claim `A → C`. The transition table and
   the prose disagree. The migration backfill and the runtime mapping
   diverge. Build a graph from both and confirm one canonical mapping.

7. **Lease / timeout invariants violated.** A lease shorter than the
   worst-case duration of the operation it protects. Always compute
   `MAX_ATTEMPTS × TIMEOUT + sum(retry_delays)` and compare to the
   declared lease. If lease ≤ worst case, the scheduler can re-claim
   a still-active job.

8. **Recovery paths that create new bugs.** A crash-recovery hook that
   maps a successful-but-uncommitted operation to a `failed` status (e.g.
   cancel-then-crash sees `fulfillmentStatus=canceled` and writes
   `gelato_failed` instead of `validated_canceled`). Walk every crash
   window: what is the remote state? What does recovery infer? Is the
   inference correct?

9. **Stale content across revisions.** The artifact says "2 tables, 4
   columns" in one section but the migration adds 6 columns. The
   downgrade DROP COLUMN ×4 contradicts the upgrade ADD COLUMN ×6.
   Architecture diagram still references a flow the spec body removed.
   Check every numeric count, list, and table for end-to-end consistency.

10. **V2-deferred items that should be in V1.** The artifact defers X to
    V2, but the V1 code depends on X (e.g. defers exhaustive httpx error
    classification, then uses precise classification in retry logic).
    Anything in V2 that the V1 code depends on is in V1, period.

11. **Allowlist vs denylist confusion.** A security or business filter
    that uses a denylist when an allowlist is required (or vice versa).
    Always ask the failure mode: when an unknown value arrives, does the
    code fail-open (denylist gap) or fail-closed (allowlist correct)?

12. **Environment guards that don't differentiate the env they need to.**
    e.g. an `is_production` boolean that returns True for both prod and
    staging, used to gate config that should differ between the two.
    The spec describes a per-env matrix but the code uses a binary flag.

13. **Multi-step DB writes without atomicity.** Two or more writes that
    must succeed together but are committed separately, leaving a crash
    window where the system is inconsistent (outbox has remote_id but
    `orders.remote_id` is NULL, or status is `validated` but no audit
    history row).

14. **External side effects inside transactions.** Emails, webhooks,
    file writes, MQ publishes triggered before the DB transaction
    commits. Commit fails → side effect already happened → unrecoverable
    inconsistency. Or commit OK + side effect fails → no retry path.

15. **Unverified claims about external behavior.** "The API will reject a
    duplicate reference", "the service always retries on 5xx", "the index
    is eventually consistent within 1s". Find every such claim and ask:
    is this in the official docs, or is it a guess that the implementation
    will depend on? Eventual consistency in particular is rarely
    documented and frequently assumed.

# Report format

Produce exactly this structure. No preamble, no signoff, no "happy to
help" lines.

```
## Verdict

[Ready / Not ready] for [implementation / merge / staging].
N blockers · N important · N minor · N stale.

## Blockers (MUST fix before proceeding)

[For each finding:
- file:line (or section reference if it's a doc artifact)
- pattern category (one of the 15 above, or "other: <name>")
- evidence (what the artifact says, what the reality is)
- suggested fix (one sentence)
]

## Important (should fix in same PR)

[Same format.]

## Minor / nits (follow-up tickets OK)

[Same format.]

## Stale / inconsistent content

[Cross-version inconsistencies that don't change behavior but signal
careless editing. Same format.]

## What is well done (be specific)

[1-3 items, file:line evidence. If you can't name three, name one.
If you can't name one, say so. Hollow praise undermines the rest.]

## Recommendation

[One paragraph. Honest. Ship as-is / fix-then-ship / split / scrap.
Would you stake your reputation on this shipping cleanly? Say so.]
```

# Tone constraints

- No validation-seeking. ("Looks great overall, just a small note..."
  is not a review.) Either it holds up or it doesn't.
- No invented findings to look thorough. Empty categories are fine if
  you really looked.
- file:line citations or it didn't happen.
- One verdict, not three.
- If the artifact passes scrutiny, say "ship it" plainly.
````

## Meta-tips to remind the user when outputting the prompt

1. **Use a different LLM than the author.** The strongest review comes from a different model family. Claude reviewing Codex's plan, or vice versa, finds more issues than Claude reviewing Claude's own plan. Same-model self-review converges on the author's blind spots.

2. **One pass at a time, but multiple passes total.** Re-running this prompt on a revised artifact routinely finds novel issues that previous passes missed. In the original Gelato session, pass 5 (after 4 prior rounds had each fixed 10-15 issues) still found 7 new blockers + cleanup items.

3. **Keep prior-pass findings out of the artifact** when re-reviewing. If the spec body still lists "v2 review found X, fixed in section Y", the reviewer will fixate on X and miss novel issues. Instead, give the reviewer a clean artifact + a separate note "this is pass N+1, prior issues addressed in commits A..B".

4. **Resist the temptation to defend.** When the reviewer flags something you believe is fine, the right next step is to verify their claim against the codebase or official docs, not to argue. In practice, most "false positives" turn out to be real once you look closely.

5. **For multi-LLM workflows:** Author LLM → Skill output → Reviewer LLM → Findings → Author LLM applies fixes → Re-run this skill → Reviewer LLM (fresh session) → repeat until "Ship it" verdict.

## Maintenance

If you discover a new failure pattern in the wild (LLM-generated artifact had a category of bug not on the 15-item list), add it to this skill. The list is empirical, not theoretical — each pattern came from a real bug found by a real review. Keep it that way.
