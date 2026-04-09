# Decision Log

## 2026-04-08 - No-cost matcher before AI

- Context:
  - Product is early and should preserve cash.
  - Current data volume is too low for high-value paid AI ranking.
- Decision:
  - Use deterministic filters + weighted ranking for matchmaking.
  - Add AI reranking only after KPI and revenue thresholds are achieved.
- Consequences:
  - Faster launch and lower infra cost.
  - Requires careful metric tracking to know when to evolve.

## 2026-04-08 - Safety and trust as first innovation pillar

- Context:
  - Trust is critical for user retention and platform quality.
- Decision:
  - Implement report/block/moderation and anti-spam before AI add-ons.
- Consequences:
  - Slightly slower feature velocity but better long-term platform health.
